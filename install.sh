#!/bin/bash
#
# Symlinks dotfiles to $HOME. Safe to re-run — backs up existing files.
#

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

link() {
  local src="$1"
  local dest="$2"

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

# Claude Code (only config we author; runtime state, plugins, and
# herdr-managed hooks are intentionally not tracked)
echo ""
echo "Claude Code:"
link "$DOTFILES/claude/settings.json"           "$HOME/.claude/settings.json"
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
echo "Done! Restart your shell or run: source ~/.zshrc"
