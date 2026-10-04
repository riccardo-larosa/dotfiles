# dotfiles

My macOS dotfiles for zsh + powerlevel10k.

## Install

```bash
git clone https://github.com/riccardo-larosa/dotfiles.git ~/Projects/github/dotfiles
cd ~/Projects/github/dotfiles
./install.sh
```

The install script symlinks everything to `$HOME` and backs up any existing files to `~/.dotfiles_backup/`.

## Prerequisites

- [Homebrew](https://brew.sh/), then install packages with `brew bundle --file=Brewfile`
- [Oh My Zsh](https://ohmyz.sh/) — `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)
- [MesloLGS Nerd Font](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md)
- [uv](https://docs.astral.sh/uv/getting-started/installation/) (Python)
- [nvm](https://github.com/nvm-sh/nvm#installing-and-updating) (Node)

## What's included

| File | Purpose |
|------|---------|
| `zsh/.zshrc` | Main shell config — oh-my-zsh, p10k, lazy nvm, uv |
| `zsh/.zprofile` | PATH additions loaded at login |
| `zsh/.p10k.zsh` | Powerlevel10k theme config |
| `.aliases` | Shared aliases (navigation, git, ls, etc.) |
| `.functions` | Shell functions (`cdf` — cd to Finder window) |
| `.tmux.conf` | tmux prefix remapped to C-a, mouse, 256 colors |
| `agents/` | Agent skills manifest `.skill-lock.json` (see below) |
| `claude/` | Claude Code config, symlinked into `~/.claude` (see below) |
| `Brewfile` | Homebrew packages (`brew bundle`) |
| `install.sh` | Symlinks dotfiles to $HOME |

## Claude Code

`install.sh` links `settings.json`, `statusline-command.sh`, `usage-aggregator.py` and the skills in `claude/skills/` into `~/.claude`.

Deliberately **not** tracked: history, sessions, telemetry, caches, installed plugins (re-installed from `enabledPlugins` in `settings.json`), `hooks/herdr-agent-state.sh` (herdr overwrites it; reinstall via herdr), and third-party skills (`mcp-builder`, `visual-explainer`, etc.).

Note: `claude/settings.json` has `/Users/riccardo.larosa` paths in `env.PATH`, the hook, and the statusline command. Edit them on a machine with a different username.

## Agent skills (`~/.agents`)

`~/.agents/skills` is the source for skills shared by Claude Code and pi (`~/.claude/skills/*` and `~/.pi/agent/skills/*` are symlinks into it).

Every skill in there is third-party (obra/superpowers, mattpocock/skills, herdrdev/herdr, ...), so none are vendored. Only the manifest, `agents/.skill-lock.json`, is tracked; `install.sh` links it. It records each skill's source repo.

Restore on a new machine:

```bash
jq -r '.skills | to_entries[] | "\(.value.source) \(.key)"' ~/.agents/.skill-lock.json |
  while read -r src name; do npx -y skills add "$src" -g -a codex -s "$name" -y </dev/null; done
```

- `-a codex` is deliberate. Codex reads `~/.agents/skills` directly, so this installs only there. Without `-a`, the CLI symlinks every skill into ~60 other agents' dotdirs under `~/`. `-a claude-code` and `-a pi` write to `~/.claude/skills` and `~/.pi` instead.
- `</dev/null` is required, otherwise `npx` swallows the loop's input and only the first skill installs.
- **Restore is not a pin.** `skills add` installs the latest upstream version, not the one in `skillFolderHash`, so restored skills can differ from the ones you had.
- To expose a skill to Claude Code, symlink it: `ln -s ../../.agents/skills/<name> ~/.claude/skills/<name>`.
- Add a new skill with `npx skills add <repo> -g -a codex -s <name> -y`; the CLI updates the lock file (it writes through the symlink), then commit the change.

## Legacy (not actively used)

- `bash/` — old bash prompt and profile
- `sublime/` — Sublime Text settings
- `iterm/` — iTerm2 color scheme
