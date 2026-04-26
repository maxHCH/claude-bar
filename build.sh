#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building ClaudeBar..."
swift build -c release 2>&1

APP="ClaudeBar.app/Contents/MacOS"
PLIST_DIR="ClaudeBar.app/Contents"
RES_DIR="ClaudeBar.app/Contents/Resources"
mkdir -p "$APP" "$PLIST_DIR" "$RES_DIR"
cp .build/release/ClaudeBar "$APP/ClaudeBar"

# Build .icns from PNG files
ICON_SRC="Sources/ClaudeBar/Assets.xcassets/AppIcon.appiconset"
ICONSET="ClaudeBar.iconset"
mkdir -p "$ICONSET"

cp "$ICON_SRC/icon_16.png"   "$ICONSET/icon_16x16.png"
cp "$ICON_SRC/icon_32.png"   "$ICONSET/icon_16x16@2x.png"
cp "$ICON_SRC/icon_32.png"   "$ICONSET/icon_32x32.png"
cp "$ICON_SRC/icon_64.png"   "$ICONSET/icon_32x32@2x.png"
cp "$ICON_SRC/icon_128.png"  "$ICONSET/icon_128x128.png"
cp "$ICON_SRC/icon_256.png"  "$ICONSET/icon_128x128@2x.png"
cp "$ICON_SRC/icon_256.png"  "$ICONSET/icon_256x256.png"
cp "$ICON_SRC/icon_512.png"  "$ICONSET/icon_256x256@2x.png"
cp "$ICON_SRC/icon_512.png"  "$ICONSET/icon_512x512.png"
cp "$ICON_SRC/icon_1024.png" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$RES_DIR/AppIcon.icns"
rm -rf "$ICONSET"
echo "✓ AppIcon.icns built"

cat > "$PLIST_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>ClaudeBar</string>
    <key>CFBundleIdentifier</key><string>com.user.claudebar</string>
    <key>CFBundleName</key><string>ClaudeBar</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSUIElement</key><true/>
    <key>NSAppTransportSecurity</key>
    <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
PLIST

echo ""
echo "✓ 完成！ClaudeBar.app 已建立"
echo ""
echo "安裝："
echo "  cp -r ClaudeBar.app /Applications/"
echo "  open /Applications/ClaudeBar.app"
