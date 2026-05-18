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

- [Homebrew](https://brew.sh/)
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
| `install.sh` | Symlinks dotfiles to $HOME |

## Legacy (not actively used)

- `bash/` — old bash prompt and profile
- `sublime/` — Sublime Text settings
- `iterm/` — iTerm2 color scheme
