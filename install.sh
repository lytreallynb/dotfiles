#!/usr/bin/env bash
# Bootstrap script — sets up a new macOS machine from this dotfiles repo.
# Idempotent: safe to re-run.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
echo "==> dotfiles root: $DOTFILES"

# ----------------------------------------------------------------------
# 1. Homebrew
# ----------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> Installing brew bundle"
brew bundle install --file="$DOTFILES/Brewfile"

# ----------------------------------------------------------------------
# 2. Symlinks for ~/.config/
# ----------------------------------------------------------------------
mkdir -p "$HOME/.config"
for src in "$DOTFILES"/config/*; do
  name="$(basename "$src")"
  target="$HOME/.config/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="$target.bak.$(date +%Y%m%d-%H%M%S)"
    echo "  backing up $target -> $backup"
    mv "$target" "$backup"
  elif [ -L "$target" ]; then
    rm "$target"
  fi
  ln -sfn "$src" "$target"
  echo "  $target -> $src"
done

# ----------------------------------------------------------------------
# 3. Symlinks for ~/.<dotfile>
# ----------------------------------------------------------------------
for src in "$DOTFILES"/home/.*; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  [ "$name" = "." ] && continue
  [ "$name" = ".." ] && continue
  target="$HOME/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="$target.bak.$(date +%Y%m%d-%H%M%S)"
    echo "  backing up $target -> $backup"
    mv "$target" "$backup"
  elif [ -L "$target" ]; then
    rm "$target"
  fi
  ln -sfn "$src" "$target"
  echo "  $target -> $src"
done

# ----------------------------------------------------------------------
# 4. SF Pro font (extract from brew cask payload — no sudo needed)
# ----------------------------------------------------------------------
if ! ls "$HOME/Library/Fonts/" 2>/dev/null | grep -qi "sf-pro"; then
  echo "==> Installing SF Pro fonts"
  brew install --cask --no-quarantine font-sf-pro 2>/dev/null || true
  DMG="$HOME/Library/Caches/Homebrew/Cask/SF-Pro.dmg--latest.dmg"
  if [ -f "$DMG" ]; then
    TMP=$(mktemp -d)
    hdiutil attach -nobrowse -noverify "$DMG"
    pkgutil --expand "/Volumes/SFProFonts/SF Pro Fonts.pkg" "$TMP/exp"
    mkdir -p "$TMP/payload"
    (cd "$TMP/payload" && cat "$TMP/exp/SFProFonts.pkg/Payload" | gunzip -dc | cpio -i)
    cp "$TMP/payload/Library/Fonts/"*.{ttf,otf} "$HOME/Library/Fonts/" 2>/dev/null || true
    hdiutil detach /Volumes/SFProFonts >/dev/null 2>&1 || true
    rm -rf "$TMP"
  fi
fi

# ----------------------------------------------------------------------
# 5. SbarLua (Lua bindings for sketchybar)
# ----------------------------------------------------------------------
if [ ! -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]; then
  echo "==> Building SbarLua"
  TMP=$(mktemp -d)
  git clone --depth=1 https://github.com/FelixKratz/SbarLua.git "$TMP/SbarLua"
  (cd "$TMP/SbarLua" && make install)
  rm -rf "$TMP"
fi

# ----------------------------------------------------------------------
# 6. SketchyBar helper binaries (cpu_load, network_load, menus)
# ----------------------------------------------------------------------
echo "==> Building sketchybar helper binaries"
(cd "$HOME/.config/sketchybar/helpers" && make)

# ----------------------------------------------------------------------
# 7. Services
# ----------------------------------------------------------------------
echo "==> Starting services"
brew services start sketchybar
brew services start borders
open -a AeroSpace || true

cat <<EOF

==> Done.

Manual steps:
  1. System Settings > Privacy & Security > Accessibility > enable AeroSpace
  2. Optional: enable macOS menu-bar auto-hide
       defaults write NSGlobalDomain _HIHideMenuBar -bool true
       killall Dock SystemUIServer

Open Neovim once so lazy.nvim finishes plugin install:
  nvim +Lazy

EOF
