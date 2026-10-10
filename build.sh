#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP_NAME="iConverter"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DESKTOP_APP="/Users/misa/Desktop/$APP_NAME.app"

echo "🔨 Building Universal 2 Binary ($APP_NAME) for ALL Mac models (Apple Silicon arm64 + Intel x86_64)..."

mkdir -p "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

SOURCES=(
  "$DIR/Sources/HardwareInfo.swift"
  "$DIR/Sources/Models.swift"
  "$DIR/Sources/ImageConverter.swift"
  "$DIR/Sources/VideoConverter.swift"
  "$DIR/Sources/AudioConverter.swift"
  "$DIR/Sources/ConversionQueue.swift"
  "$DIR/Sources/Views/DropZoneView.swift"
  "$DIR/Sources/Views/ItemRowView.swift"
  "$DIR/Sources/Views/SettingsView.swift"
  "$DIR/Sources/Views/ContentView.swift"
  "$DIR/Sources/iConverterApp.swift"
)

# 1. Compile for Apple Silicon (M1, M2, M3, M4, M5, Pro, Max, Ultra)
echo "   Compiling for Apple Silicon (arm64)..."
swiftc -O -parse-as-library \
  -target arm64-apple-macos13.0 \
  "${SOURCES[@]}" \
  -o "$BUILD_DIR/${APP_NAME}_arm64"

# 2. Compile for Intel Macs (x86_64)
echo "   Compiling for Intel (x86_64)..."
swiftc -O -parse-as-library \
  -target x86_64-apple-macos13.0 \
  "${SOURCES[@]}" \
  -o "$BUILD_DIR/${APP_NAME}_x86_64"

# 3. Merge into Universal 2 Binary using lipo
echo "   Creating Universal 2 Binary..."
lipo -create "$BUILD_DIR/${APP_NAME}_arm64" "$BUILD_DIR/${APP_NAME}_x86_64" \
  -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

rm -f "$BUILD_DIR/${APP_NAME}_arm64" "$BUILD_DIR/${APP_NAME}_x86_64"

# Copy Resources
cp "$DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Deploy to Desktop
echo "🚀 Deploying Universal $APP_NAME.app directly to Desktop..."
rm -rf "$DESKTOP_APP"
cp -R "$APP_BUNDLE" "$DESKTOP_APP"
xattr -cr "$DESKTOP_APP" 2>/dev/null || true

/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo "✅ Universal 2 Binary successfully built! Compatible with ALL MacBook, Mac Studio, Mac mini, iMac, and Mac Pro models."
