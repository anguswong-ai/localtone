#!/bin/bash
#
# Builds LocalTone as a proper macOS .app bundle and launches it.
#
# Running the executable directly with `swift run` produces a bare binary with
# no Info.plist / bundle identifier. In that mode macOS will not give keyboard
# focus to the text fields inside system Save/Open panels, so the ringtone name
# field cannot be edited. Wrapping the binary in a real .app bundle fixes that.
#
# Usage: ./build-app.sh

set -euo pipefail

CONFIG="release"
APP_NAME="LocalTone"

cd "$(dirname "$0")"

echo "Building $APP_NAME ($CONFIG)..."
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP_BUNDLE="$BIN_DIR/$APP_NAME.app"

echo "Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.localtone.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Built: $APP_BUNDLE"
echo "Launching $APP_NAME..."
open "$APP_BUNDLE"
