# DOTFILES

macOS dev environment: zsh + oh-my-zsh + powerlevel10k, tmux, Homebrew.
Files are symlinked into `$HOME` by `install.sh` (no Stow yet).

## STRUCTURE

```
dotfiles/
├── .aliases          # Shared aliases       -> ~/.aliases
├── .functions        # Shell functions      -> ~/.functions
├── .tmux.conf        # tmux config          -> ~/.tmux.conf
├── zsh/              # .zshrc, .zprofile, .p10k.zsh -> ~/
├── agents/           # ~/.agents/.skill-lock.json only; skills are third-party and restored, not vendored
├── claude/           # Claude Code config, linked into ~/.claude (settings.json, statusline, skills/)
├── Brewfile          # Homebrew packages (brew bundle)
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
| Claude Code settings / statusline / own skills | `claude/` (edit here; `~/.claude` entries are symlinks) |
| Add a brew package | `Brewfile`, then `brew bundle --file=Brewfile` |
| Link a new file into $HOME | add a `link` line in `install.sh` |

## CONVENTIONS

- Home-dir files are symlinks to this repo. Edit the repo copy, not a copy in `$HOME`.
- `install.sh` must stay idempotent and back up anything it replaces to `~/.dotfiles_backup/`.
- Use `$HOME`, not hardcoded `/Users/<name>` paths.
- nvm is lazy-loaded for fast startup. Don't replace it with an eager `source nvm.sh`.
- Commit small, one concern per commit.

## ANTI-PATTERNS

- Committing secrets, tokens, or `*.local` files (see `.gitignore`).
- Committing Claude/agent runtime state (history, sessions, telemetry, plugin caches).
- Letting installers append to `zsh/.zshrc` or `zsh/.zprofile` unreviewed. Installers for
  Codex, Antigravity and similar tools add PATH lines. Review, dedupe, or move them deliberately.
- Tracking `~/.claude` runtime state or herdr-managed files (`hooks/herdr-agent-state.sh`). Only add files to `claude/` that we author.
- Vendoring third-party skills into this repo (public; most are MIT and need their notice). Restore them via `.skill-lock.json`; restore installs latest upstream, not a pinned version.
- Running `skills add` without `-a codex`: it symlinks into ~60 other agents' dotdirs under `~/`.
- Editing legacy dirs (`bash/`, `sublime/`, `iterm/`) unless asked.
