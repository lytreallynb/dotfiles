#!/usr/bin/env bash
# Pull live configs back into the dotfiles repo.
# Run this after editing files in ~/.config/ or ~/.zshrc directly.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "==> Syncing live configs into $DOTFILES"

# ~/.config/X -> dotfiles/config/X
for name in aerospace borders cava fastfetch ghostty kitty nvim sketchybar; do
  if [ -d "$HOME/.config/$name" ]; then
    rsync -a --delete \
      --exclude '.DS_Store' \
      --exclude 'helpers/**/bin/' \
      --exclude 'helpers/**/*.o' \
      --exclude 'lazy-lock.json.local' \
      "$HOME/.config/$name/" "$DOTFILES/config/$name/"
    echo "  config/$name"
  fi
done

# ~/.<dotfile> -> dotfiles/home/.<dotfile>
for name in .zshrc .zprofile .tmux.conf .gitconfig; do
  if [ -f "$HOME/$name" ]; then
    cp "$HOME/$name" "$DOTFILES/home/$name"
    echo "  home/$name"
  fi
done

# Refresh Brewfile
brew bundle dump --force --file="$DOTFILES/Brewfile"
echo "  Brewfile"

echo "==> Done. Review changes with: cd $DOTFILES && git status"
