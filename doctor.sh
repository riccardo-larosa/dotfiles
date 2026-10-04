#!/bin/bash
#
# Read-only health check for this dotfiles setup. Changes nothing.
# Exit 1 if any check fails. Warnings do not fail the run.
#
#   ./doctor.sh
#

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
FAIL=0
WARN=0

section() { echo ""; echo "$1:"; }
ok()      { echo "  ✓ $1"; }
fail()    { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
warn()    { echo "  ! $1"; WARN=$((WARN + 1)); }
have()    { command -v "$1" >/dev/null 2>&1; }

# --- Symlinks (single source of truth: install.sh --check) -------------------
section "Symlinks"
out="$("$DOTFILES/install.sh" --check 2>&1)"
rc=$?
good=$(printf '%s\n' "$out" | grep -c '^  ✓')
if [ "$rc" -eq 0 ]; then
  ok "$good links point into the repo"
else
  printf '%s\n' "$out" | grep '^  ✗'
  FAIL=$((FAIL + $(printf '%s\n' "$out" | grep -c '^  ✗')))
  warn "run ./install.sh to repair (existing files are backed up first)"
fi

# --- Dangling symlinks in skill directories ---------------------------------
section "Dangling links"
dangling=0
for d in "$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.pi/agent/skills"; do
  [ -d "$d" ] || continue
  while IFS= read -r l; do
    [ -n "$l" ] && { fail "$l -> $(readlink "$l") (target missing)"; dangling=1; }
  done < <(find "$d" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
done
[ "$dangling" -eq 0 ] && ok "none in ~/.claude/skills, ~/.agents/skills, ~/.pi/agent/skills"

# --- Things .zshrc sources or runs without guards (missing = broken shell) ---
section "Shell prerequisites"
[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ] && ok "oh-my-zsh" || fail "oh-my-zsh missing (.zshrc sources it)"
[ -f "$HOME/.local/bin/env" ]          && ok "~/.local/bin/env (from uv)" || fail "~/.local/bin/env missing (.zshrc sources it)"
have uv                                && ok "uv" || fail "uv not on PATH (.zshrc runs 'uv generate-shell-completion')"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  [ -d "$HOME/.oh-my-zsh/custom/plugins/$p" ] && ok "plugin $p" || warn "plugin $p missing (see README)"
done
[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] && ok "powerlevel10k theme" || warn "powerlevel10k theme missing"
[ -d "$HOME/.nvm" ] && ok "nvm" || warn "nvm missing (.zshrc lazy-loads it)"
have cursor && ok "cursor (EDITOR)" || warn "cursor not on PATH but EDITOR=cursor"

# --- Packages ----------------------------------------------------------------
section "Packages"
if have brew; then
  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
    ok "Brewfile satisfied"
  else
    warn "Brewfile not satisfied (missing or outdated). See: brew bundle check --verbose --file=Brewfile"
  fi
else
  fail "brew not installed"
fi
for t in git zsh jq rg gh; do
  have "$t" && ok "$t" || warn "$t not on PATH"
done

# --- herdr (terminal workspace manager for agents; replaces tmux) -------------
section "herdr"
if have herdr; then
  ok "herdr on PATH ($(herdr --version 2>/dev/null | head -1))"
  if hout="$(herdr config check 2>&1)"; then
    ok "config.toml valid"
  else
    fail "herdr config check failed: $hout"
  fi
  [ -f "$HOME/.pi/agent/extensions/herdr-agent-state.ts" ] && ok "pi integration installed" \
    || warn "pi integration missing (run: herdr integration install pi)"
  if [ -d "$HOME/.claude" ]; then
    [ -f "$HOME/.claude/hooks/herdr-agent-state.sh" ] && ok "claude integration installed" \
      || warn "claude integration missing (run: herdr integration install claude)"
  fi
else
  warn "herdr not on PATH (install: curl -fsSL https://herdr.dev/install.sh | sh, or brew install herdr)"
fi

# --- pi (primary agent) ------------------------------------------------------
# Never call `pi list` here: it installs missing packages as a side effect.
section "pi"
have pi && ok "pi on PATH" || warn "pi not on PATH (npm i -g @earendil-works/pi-coding-agent)"
PI_SETTINGS="$HOME/.pi/agent/settings.json"
if have jq && [ -f "$PI_SETTINGS" ]; then
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    case "$pkg" in
      npm:*)
        name="${pkg#npm:}"; name="${name%@[0-9]*}"
        dir="$HOME/.pi/agent/npm/node_modules/$name" ;;
      https://github.com/*|git:github.com/*)
        repo="${pkg#https://github.com/}"; repo="${repo#git:github.com/}"; repo="${repo%.git}"; repo="${repo%@*}"
        dir="$HOME/.pi/agent/git/github.com/$repo" ;;
      *) continue ;;
    esac
    [ -d "$dir" ] && ok "package installed: $pkg" || warn "package declared but not installed: $pkg (run: pi update --extensions)"
  done < <(jq -r '.packages[]? | if type=="string" then . else .source // empty end' "$PI_SETTINGS")
fi

# --- Config sanity -----------------------------------------------------------
section "Config"
for f in .zshrc .zprofile; do
  zsh -n "$DOTFILES/zsh/$f" 2>/dev/null && ok "zsh syntax: $f" || fail "zsh syntax error in zsh/$f"
done
bash -n "$DOTFILES/install.sh" && ok "bash syntax: install.sh" || fail "syntax error in install.sh"
for f in claude/statusline-command.sh claude/usage-aggregator.py; do
  [ -x "$DOTFILES/$f" ] && ok "executable: $f" || fail "$f is not executable"
done
if have jq; then
  for f in "$HOME/.claude/settings.json" "$HOME/.agents/.skill-lock.json"; do
    jq -e . "$f" >/dev/null 2>&1 && ok "valid JSON: ${f#$HOME/}" || fail "invalid or missing JSON: ${f#$HOME/}"
  done
  # Every skill in the lock file should exist on disk.
  missing=""
  for s in $(jq -r '.skills | keys[]' "$HOME/.agents/.skill-lock.json" 2>/dev/null); do
    [ -d "$HOME/.agents/skills/$s" ] || missing="$missing $s"
  done
  if [ -z "$missing" ]; then
    ok "all skills in the lock file are installed"
  else
    warn "in lock but not installed:$missing (restore: see README, 'Agent skills')"
  fi
else
  warn "jq missing: skipped JSON and skill-lock checks"
fi

# --- Repo hygiene (this repo is public) ---------------------------------------
section "Repo"
cd "$DOTFILES" || exit 1
if git grep -nIE '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY)' >/dev/null 2>&1; then
  fail "possible secret in a tracked file (run: git grep -nIE 'ghp_|sk-|AKIA|PRIVATE KEY')"
else
  ok "no obvious secrets in tracked files"
fi
if git ls-files | grep -qE '(^|/)(settings\.local\.json|\.env|auth\.json|trust\.json|models-store\.json)$'; then
  fail "a local-only or credential file is tracked (settings.local.json, .env, pi auth/trust/models-store)"
else
  ok "no local-only files tracked"
fi
if [ -n "$(git status --porcelain)" ]; then
  warn "uncommitted changes (installers like Codex append to zsh/ files; review them)"
else
  ok "working tree clean"
fi
ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
[ "$ahead" -gt 0 ] && warn "$ahead commit(s) not pushed" || ok "nothing unpushed"

# --- Summary ------------------------------------------------------------------
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "$FAIL failed, $WARN warning(s)."
  exit 1
fi
echo "All checks passed ($WARN warning(s))."
exit 0
