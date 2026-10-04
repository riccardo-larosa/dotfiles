# DOTFILES

macOS dev environment: zsh + oh-my-zsh + powerlevel10k, herdr (replaces tmux), Homebrew, and coding-agent config.
**pi is the primary agent**; Claude Code is also configured (secondary).
Files are symlinked into `$HOME` by `install.sh` (no Stow yet).

## STRUCTURE

```
dotfiles/
├── .aliases          # Shared aliases       -> ~/.aliases
├── .functions        # Shell functions      -> ~/.functions
├── zsh/              # .zshrc, .zprofile, .p10k.zsh -> ~/
├── herdr/            # config.toml only -> ~/.config/herdr (rest of that dir is runtime state)
├── pi/               # PRIMARY agent: settings.json + extensions/*.ts, linked into ~/.pi/agent (per-file)
├── agents/           # ~/.agents/.skill-lock.json only; skills are third-party and restored, not vendored
├── claude/           # SECONDARY: Claude Code config, linked into ~/.claude (settings.json, statusline, skills/)
├── NOTICES.md        # Provenance + license text for third-party files (pi extension, claude skills)
├── Brewfile          # Homebrew packages (brew bundle)
├── doctor.sh         # Read-only health check (links, prereqs, config, repo hygiene)
├── install.sh        # Symlinks files into $HOME, backs up existing ones
├── bash/ sublime/ iterm/   # Legacy, not actively used
└── .claude/          # Project-local Claude settings (settings.local.json is gitignored)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add alias | `.aliases` |
| Add shell function | `.functions` |
| PATH for login shells | `zsh/.zprofile` |
| Interactive shell config, plugins, nvm, uv | `zsh/.zshrc` |
| Prompt appearance | `zsh/.p10k.zsh` (regenerate with `p10k configure`) |
| Add/restore an agent skill | `npx skills add <repo> -g -a codex -s <name> -y` (see README; never omit `-a`) |
| herdr config | `herdr/config.toml` (herdr writes it through the symlink; validate with `herdr config check`) |
| herdr/agent integrations | `herdr integration install pi\|claude` (generated files, never tracked) |
| pi settings (packages, models, theme) | `pi/settings.json` (edit here; pi also writes it through the symlink, so commit its diffs) |
| pi local extension | `pi/extensions/<name>.ts`, then add provenance to `NOTICES.md` if not original |
| Restore pi packages on a new machine | `pi update --extensions` (reads `pi/settings.json`) |
| Claude Code settings / statusline / own skills | `claude/` (edit here; `~/.claude` entries are symlinks) |
| Add a brew package | `Brewfile`, then `brew bundle --file=Brewfile` |
| Link a new file into $HOME | add a `link` line in `install.sh` (`doctor.sh` checks it automatically via `install.sh --check`) |
| Health check / verify setup | `./doctor.sh` (run after any change to `install.sh`, `zsh/`, `herdr/`, `pi/`, `claude/`, `agents/`) |

## CONVENTIONS

- Home-dir files are symlinks to this repo. Edit the repo copy, not a copy in `$HOME`.
- `install.sh` must stay idempotent and back up anything it replaces to `~/.dotfiles_backup/`.
- Use `$HOME`, not hardcoded `/Users/<name>` paths.
- nvm is lazy-loaded for fast startup. Don't replace it with an eager `source nvm.sh`.
- Commit small, one concern per commit.
- `install.sh --check` and `doctor.sh` must stay read-only. New unguarded `source`/command lines in `zsh/.zshrc` should get a matching prerequisite check in `doctor.sh`.

## ANTI-PATTERNS

- Committing secrets, tokens, or `*.local` files (see `.gitignore`).
- Committing agent runtime state or credentials: pi's `auth.json`, `trust.json`, `models-store.json`, `sessions/`, `npm/`, `git/`; Claude's history, sessions, telemetry, plugin caches. `doctor.sh` fails if `auth.json`/`trust.json`/`models-store.json` get tracked.
- Letting installers append to `zsh/.zshrc` or `zsh/.zprofile` unreviewed. Installers for
  Codex, Antigravity and similar tools add PATH lines. Review, dedupe, or move them deliberately.
- Tracking herdr-generated files: `~/.pi/agent/extensions/herdr-agent-state.ts` and `~/.claude/hooks/herdr-agent-state.sh`. Restore with `herdr integration install pi|claude`. Only add files to `pi/` and `claude/` that we author or have attributed.
- Re-adding tmux config. herdr replaced tmux; the old config is in git history (tag `v0.4-pi-first`).
- Tracking herdr runtime state (`herdr*.sock`, `*.log`, `session.json`, `session-snapshots/`, `release-notes.json`). Only `herdr/config.toml` is tracked.
- Linking all of `~/.pi/agent/extensions` as one directory. It also holds the herdr-generated file, so link per file.
- Calling `pi list` from scripts or checks. It installs missing packages as a side effect; inspect the package directories on disk instead.
- Adding a skill to `claude/skills/` or an extension to `pi/extensions/` without recording its source and license in `NOTICES.md`.
- Vendoring third-party skills into this repo (public; most are MIT and need their notice). Restore them via `.skill-lock.json`; restore installs latest upstream, not a pinned version.
- Running `skills add` without `-a codex`: it symlinks into ~60 other agents' dotdirs under `~/`.
- Editing legacy dirs (`bash/`, `sublime/`, `iterm/`) unless asked.
