#!/bin/bash
#
# Symlinks dotfiles to $HOME. Safe to re-run — backs up existing files.
#

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

link() {
  local src="$1"
  local dest="$2"

  # If destination exists and isn't already the correct symlink, back it up
  if [ -e "$dest" ] && [ "$(readlink "$dest")" != "$src" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    echo "  backed up $(basename "$dest") → $BACKUP_DIR/"
  fi

  ln -sf "$src" "$dest"
  echo "  ✓ $(basename "$dest")"
}

echo "Installing dotfiles from $DOTFILES"
echo ""

# Shared
echo "Shared:"
link "$DOTFILES/.aliases"    "$HOME/.aliases"
link "$DOTFILES/.functions"  "$HOME/.functions"
link "$DOTFILES/.tmux.conf"  "$HOME/.tmux.conf"

# Zsh
echo ""
echo "Zsh:"
link "$DOTFILES/zsh/.zshrc"     "$HOME/.zshrc"
link "$DOTFILES/zsh/.zprofile"  "$HOME/.zprofile"
link "$DOTFILES/zsh/.p10k.zsh"  "$HOME/.p10k.zsh"

echo ""
echo "Done! Restart your shell or run: source ~/.zshrc"
