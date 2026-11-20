# Desktop pets

Pixel pets that walk along the bottom of the screen: Mochi plus my two cats.
Plain AppKit, no dependencies.

| Pet  | Special move                         |
|------|--------------------------------------|
| Mochi | Reminds you to stretch after 50 min of activity |
| 灰灰 | Sits in a cardboard box, side-eyeing you |
| 橘子 | Rolls onto his back, paws up          |

## Build and run

```bash
./build.sh                         # builds Mochi.app here
cp -R Mochi.app ~/Applications/    # optional
open Mochi.app
```

`install.sh` at the repo root does this automatically and installs to `~/Applications/`.

## Controls

- Left click: talk / jump (cats sometimes do their special move)
- Drag: pick up and drop
- Right click: menu (special move, sleep, send one home, bring everyone back, quit)
- Pets fall asleep after 5 minutes without input and wake when you return.

## Editing sprites

Sprites and per-pet settings (names, lines, speed) live in `Sprites.swift`.
Preview every frame as a PNG before rebuilding:

```bash
swiftc -target arm64-apple-macos13.0 Sprites.swift tools/main.swift -o /tmp/preview && /tmp/preview /tmp/sprites.png
```

Note: the build pins `-target arm64-apple-macos13.0`; without it the binary's
minimum OS can exceed what LaunchServices accepts and `open` fails with -10825.
