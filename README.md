# dotfiles

My macOS development environment, captured so I can rebuild a machine from scratch.

## Stack

| Layer            | Tool                       | Config path                |
|------------------|----------------------------|----------------------------|
| Window manager   | [AeroSpace](https://github.com/nikitabobko/AeroSpace) | `config/aerospace/`        |
| Status bar       | [SketchyBar](https://github.com/FelixKratz/SketchyBar) (Lua) | `config/sketchybar/`       |
| Window borders   | [JankyBorders](https://github.com/FelixKratz/JankyBorders) | `config/borders/`          |
| Visual CLI        | [fastfetch](https://github.com/fastfetch-cli/fastfetch) + [cava](https://github.com/karlstav/cava) | `config/fastfetch/`, `config/cava/` |
| Editor           | [Neovim](https://neovim.io/) (lazy.nvim) | `config/nvim/`             |
| Terminal         | [Ghostty](https://ghostty.org/) + [Kitty](https://sw.kovidgoyal.net/kitty/) | `config/ghostty/`, `config/kitty/` |
| Shell            | zsh                        | `home/.zshrc`              |
| Multiplexer      | tmux                       | `home/.tmux.conf`          |

## Layout

```
dotfiles/
├── Brewfile              # All Homebrew formulae and casks
├── config/               # → mirrors ~/.config/
│   ├── aerospace/
│   ├── borders/
│   ├── cava/
│   ├── fastfetch/
│   ├── ghostty/
│   ├── kitty/
│   ├── nvim/
│   └── sketchybar/
├── home/                 # → mirrors ~/  (dotfiles)
│   ├── .gitconfig
│   ├── .tmux.conf
│   ├── .zprofile
│   └── .zshrc
├── install.sh            # Fresh-machine bootstrap
└── sync.sh               # Pull live configs back into the repo
```

## Fresh-machine install

```bash
git clone git@github.com:lytreallynb/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:

1. Install Homebrew if missing
2. `brew bundle install --file=./Brewfile`
3. Symlink everything in `config/` into `~/.config/` (existing files backed up to `~/.config/<name>.bak`)
4. Symlink everything in `home/` into `~/`
5. Build SbarLua and the SketchyBar helper binaries
6. Patch SF Pro fonts into `~/Library/Fonts/` from the installed brew cask (no sudo)
7. Start `borders` and `sketchybar` services and launch `AeroSpace`

## Manual steps after install.sh

### 1. Accessibility permissions
- **AeroSpace**: System Settings → Privacy & Security → Accessibility → enable AeroSpace.app
- **cliclick** (used by sketchybar's hover-watcher): not strictly needed for `cliclick p` (read-only)

### 2. macOS menu bar auto-hide
The hover-watcher script hides sketchybar when your cursor reaches the top edge so the macOS menu bar can show. Enable system auto-hide too:
```bash
defaults write NSGlobalDomain _HIHideMenuBar -bool true
killall Dock SystemUIServer
```

### 3. SF Pro fonts
`install.sh` extracts SF Pro from the brew cask payload (no sudo) and drops it in `~/Library/Fonts/`. If that fails:
```bash
brew install --cask font-sf-pro
# enter password when prompted
```

## Day-to-day workflow

After editing live configs in `~/.config/...` or `~/.zshrc`, run:

```bash
cd ~/dotfiles
./sync.sh
git add -A
git commit -m "tweak <thing>"
git push
```

`sync.sh` copies the live configs back into the repo so the diff reflects what you've changed.

## Window manager keybindings (AeroSpace)

All shortcuts use **Option (⌥)** as the modifier.

| Keys                        | Action                          |
|-----------------------------|---------------------------------|
| `⌥ + H/J/K/L`               | Focus left / down / up / right  |
| `⌥ + ⇧ + H/J/K/L`           | Move window left / down / up / right |
| `⌥ + 1..9`                  | Switch to workspace 1..9        |
| `⌥ + ⇧ + 1..9`              | Move window to workspace 1..9   |
| `⌥ + F`                     | Toggle fullscreen               |
| `⌥ + /`                     | Toggle floating ↔ tiling        |
| `⌥ + -` / `⌥ + =`           | Resize smaller / larger         |

New windows default to **floating** (set in `aerospace.toml` via `[[on-window-detected]] run = ['layout floating']`). Toggle a window into a tiled layout with `⌥ + /`.

## Window snapping with Magnet (or Rectangle)

For Magnet-style snap shortcuts (`Ctrl+⌥+←` for left-half etc.), the window **must be floating**, not tiled. AeroSpace will fight Magnet otherwise — you'll resize, then the window snaps back to its tile.

- New windows default to floating (`[[on-window-detected]] run = ['layout floating']`)
- For windows that were already open before this rule was added, toggle them with `⌥ + /` once

## Desktop decoration

- **Side color line / window border**: `config/borders/bordersrc`, symlinked to `~/.config/borders/bordersrc` by `install.sh`.
- **Active border color**: `active_color=0xff7aa2f7`
- **Inactive border color**: `inactive_color=0xff292e42`
- **Status bar styling**: `config/sketchybar/colors.lua`, `config/sketchybar/settings.lua`, and per-widget files under `config/sketchybar/items/`.
- **Close-window workspace behavior**: `persistent-workspaces = ["1", ..., "9"]` in `config/aerospace/aerospace.toml` keeps empty workspaces alive, so closing the last window does not jump back to workspace `1`.

## Notes / gotchas

- **SketchyBar helpers are pre-compiled out of the repo.** `install.sh` rebuilds them — depends on `make` and `clang` from Xcode CLI tools.
- **SbarLua** lives at `~/.local/share/sketchybar_lua/sketchybar.so`. `install.sh` clones and builds it.
- **Workspaces only show when populated** — `config/sketchybar/items/spaces.lua` queries AeroSpace for non-empty workspaces and hides the rest. The focused workspace is always visible.
- **CPU/RAM widgets** poll via the compiled `cpu_load` helper plus `vm_stat`, color-coded by load: muted < 40%, yellow > 40%, orange > 60%, red > 80%.
- **Hover-to-hide**: `config/sketchybar/hover_watcher.sh` polls cursor Y position via `cliclick` and hides the bar when within 35px of the screen top.
