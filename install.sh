#!/bin/bash
#
# Symlinks dotfiles to $HOME. Safe to re-run — backs up existing files.
#
# Usage:
#   ./install.sh           create/refresh symlinks
#   ./install.sh --check   read-only: verify every link, change nothing (exit 1 if any are bad)
#

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

CHECK=0
BAD=0
case "${1:-}" in
  "") ;;
  --check) CHECK=1 ;;
  -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
esac

link() {
  local src="$1"
  local dest="$2"
  local name
  name="$(basename "$dest")"

  if [ "$CHECK" -eq 1 ]; then
    # Read-only: never create, move, or relink anything here.
    if [ ! -L "$dest" ]; then
      if [ -e "$dest" ]; then
        echo "  ✗ $name: exists but is not a symlink (replaced by a regular file?)"
      else
        echo "  ✗ $name: missing"
      fi
      BAD=$((BAD + 1))
    elif [ "$(readlink "$dest")" != "$src" ]; then
      echo "  ✗ $name: points to $(readlink "$dest"), expected $src"
      BAD=$((BAD + 1))
    elif [ ! -e "$src" ]; then
      echo "  ✗ $name: link is correct but the repo file is missing"
      BAD=$((BAD + 1))
    else
      echo "  ✓ $name"
    fi
    return
  fi

  mkdir -p "$(dirname "$dest")"

  # If destination exists and isn't already the correct symlink, back it up
  if [ -e "$dest" ] && [ "$(readlink "$dest")" != "$src" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    echo "  backed up $(basename "$dest") → $BACKUP_DIR/"
  fi

  # -n: treat an existing symlink-to-dir as a file, so re-runs replace it
  # instead of creating a link inside the target directory.
  ln -sfn "$src" "$dest"
  echo "  ✓ $(basename "$dest")"
}

if [ "$CHECK" -eq 1 ]; then
  echo "Checking dotfiles links from $DOTFILES"
else
  echo "Installing dotfiles from $DOTFILES"
fi
echo ""

# Shared
echo "Shared:"
link "$DOTFILES/.aliases"    "$HOME/.aliases"
link "$DOTFILES/.functions"  "$HOME/.functions"

# Zsh
echo ""
echo "Zsh:"
link "$DOTFILES/zsh/.zshrc"     "$HOME/.zshrc"
link "$DOTFILES/zsh/.zprofile"  "$HOME/.zprofile"
link "$DOTFILES/zsh/.p10k.zsh"  "$HOME/.p10k.zsh"

# herdr (terminal workspace manager for agents; replaces tmux). Only config.toml is tracked.
# The rest of ~/.config/herdr is runtime state (sockets, logs, session.json, snapshots).
# herdr writes config.toml through the symlink (e.g. `herdr config reset-keys`).
echo ""
echo "herdr:"
link "$DOTFILES/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# pi (primary agent). Per-file links for extensions: ~/.pi/agent/extensions also holds
# herdr-agent-state.ts, which herdr generates and overwrites, so it must stay untracked.
# Never track auth.json, trust.json, models-store.json, sessions/, npm/ or git/.
# Packages in settings.json are restored by pi itself (see README).
echo ""
echo "pi:"
link "$DOTFILES/pi/settings.json" "$HOME/.pi/agent/settings.json"
link "$DOTFILES/pi/AGENTS.md"     "$HOME/.pi/agent/AGENTS.md"
for ext in "$DOTFILES"/pi/extensions/*.ts; do
  [ -e "$ext" ] || continue
  link "$ext" "$HOME/.pi/agent/extensions/$(basename "$ext")"
done

# Claude Code (secondary; only config we author; runtime state, plugins, and
# herdr-managed hooks are intentionally not tracked)
echo ""
echo "Claude Code:"
link "$DOTFILES/claude/settings.json"           "$HOME/.claude/settings.json"
link "$DOTFILES/claude/CLAUDE.md"               "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/statusline-command.sh"   "$HOME/.claude/statusline-command.sh"
link "$DOTFILES/claude/usage-aggregator.py"     "$HOME/.claude/usage-aggregator.py"
for skill in "$DOTFILES"/claude/skills/*/; do
  name="$(basename "$skill")"
  link "$DOTFILES/claude/skills/$name" "$HOME/.claude/skills/$name"
done

# Agent skills manifest (~/.agents). Skill contents are third-party and are
# restored from this lock file, not vendored (see README).
echo ""
echo "Agent skills:"
link "$DOTFILES/agents/.skill-lock.json" "$HOME/.agents/.skill-lock.json"

echo ""
if [ "$CHECK" -eq 1 ]; then
  if [ "$BAD" -gt 0 ]; then
    echo "$BAD link(s) need attention. Run ./install.sh to fix."
    exit 1
  fi
  echo "All links OK."
  exit 0
fi
echo "Done! Restart your shell or run: source ~/.zshrc"
