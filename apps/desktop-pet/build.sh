#!/bin/bash
# Builds Mochi.app (with icon) and installs it to ~/Applications.
# Only one copy is kept so Spotlight shows a single Mochi.
set -euo pipefail
cd "$(dirname "$0")"
DEST="$HOME/Applications/Mochi.app"
TARGET="-target arm64-apple-macos13.0"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

APP="$WORK/Mochi.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -swift-version 5 $TARGET Sprites.swift main.swift -o "$APP/Contents/MacOS/Mochi"

# App icon rendered from the Mochi sprite
swiftc -swift-version 5 $TARGET Sprites.swift tools/main.swift -o "$WORK/preview"
"$WORK/preview" --icon "$WORK/icon.png"
ICONSET="$WORK/Mochi.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z $size $size "$WORK/icon.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) "$WORK/icon.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Mochi.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Mochi</string>
  <key>CFBundleDisplayName</key><string>Mochi</string>
  <key>CFBundleIdentifier</key><string>com.lytreallynb.mochi</string>
  <key>CFBundleExecutable</key><string>Mochi</string>
  <key>CFBundleIconFile</key><string>Mochi</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP" >/dev/null

pkill -x Mochi 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
touch "$DEST"
echo "Installed $DEST"
