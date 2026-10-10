#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP_NAME="iConventer"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DESKTOP_APP="/Users/misa/Desktop/$APP_NAME.app"

echo "🔨 Building $APP_NAME for Apple Silicon (arm64)..."

mkdir -p "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compile Swift sources with maximum optimizations
swiftc -O -parse-as-library \
  -target arm64-apple-macos14.0 \
  "$DIR/Sources/HardwareInfo.swift" \
  "$DIR/Sources/Models.swift" \
  "$DIR/Sources/ImageConverter.swift" \
  "$DIR/Sources/VideoConverter.swift" \
  "$DIR/Sources/AudioConverter.swift" \
  "$DIR/Sources/ConversionQueue.swift" \
  "$DIR/Sources/Views/DropZoneView.swift" \
  "$DIR/Sources/Views/ItemRowView.swift" \
  "$DIR/Sources/Views/SettingsView.swift" \
  "$DIR/Sources/Views/ContentView.swift" \
  "$DIR/Sources/main.swift" \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Resources
cp "$DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Deploy to Desktop
echo "🚀 Deploying $APP_NAME.app directly to Desktop..."
rm -rf "$DESKTOP_APP"
cp -R "$APP_BUNDLE" "$DESKTOP_APP"
xattr -cr "$DESKTOP_APP" 2>/dev/null || true

# Refresh macOS Services database
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo "✅ $APP_NAME.app successfully built and deployed to Desktop!"
