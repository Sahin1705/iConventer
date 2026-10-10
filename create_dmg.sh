#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP_NAME="iConventer"
APP_PATH="$DIR/build/$APP_NAME.app"
DMG_NAME="iConventer"
OUTPUT_DMG="/Users/misa/Desktop/$DMG_NAME.dmg"
TEMP_DMG="/tmp/$DMG_NAME-temp.dmg"
STAGING_DIR="/tmp/dmg_staging"

# Ensure app is built
if [ ! -d "$APP_PATH" ]; then
    echo "App not built yet. Building..."
    "$DIR/build.sh"
fi

echo "📦 Preparing sleek DMG installer for $APP_NAME..."

rm -rf "$STAGING_DIR" "$TEMP_DMG" "$OUTPUT_DMG"
mkdir -p "$STAGING_DIR/.background"

# Copy App Bundle
cp -R "$APP_PATH" "$STAGING_DIR/"

# Symlink to /Applications
ln -s /Applications "$STAGING_DIR/Applications"

# Copy DMG Background
cp "$DIR/Resources/dmg_background.png" "$STAGING_DIR/.background/background.png"

# Add Finder Quick Action Installer script inside DMG
cat << 'EOF' > "$STAGING_DIR/Hızlı İşlemi Yükle.command"
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEST="$HOME/Library/Services/iConventer ile Çevir.workflow"

mkdir -p "$HOME/Library/Services"
rm -rf "$DEST"

# Create Quick Action
mkdir -p "$DEST/Contents"

cat << 'PLIST' > "$DEST/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>tr</string>
    <key>CFBundleIdentifier</key>
    <string>com.misa.services.iconventer</string>
    <key>CFBundleName</key>
    <string>iConventer ile Çevir</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>iConventer ile Çevir</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSApplicationIdentifier</key>
                <string>com.apple.finder</string>
            </dict>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
                <string>public.data</string>
                <string>public.movie</string>
                <string>public.image</string>
                <string>public.audio</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

cat << 'WFLOW' > "$DEST/Contents/document.wflow"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <false/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.path</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>for f in "$@"
do
    open -a "iConventer" "$f" 2>/dev/null || open -a "/Applications/iConventer.app" "$f" 2>/dev/null || open -a "$HOME/Desktop/iConventer.app" "$f"
done
</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/zsh</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>CFBundleVersion</key>
                <string>2.0.3</string>
            </dict>
        </dict>
    </array>
    <key>workflowMetaData</key>
    <dict>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
WFLOW

/System/Library/CoreServices/pbs -update 2>/dev/null || true
osascript -e 'display notification "Finder sağ tık 'iConventer ile Çevir' hızlı işlemi başarıyla yüklendi!" with title "iConventer"'
echo "✅ Finder Hızlı İşlemi başarıyla yüklendi! Artık herhangi bir dosyaya sağ tıklayıp Hızlı İşlemler > iConventer ile Çevir diyebilirsiniz."
EOF
chmod +x "$STAGING_DIR/Hızlı İşlemi Yükle.command"

# Calculate size needed
STAGING_SIZE=$(du -sk "$STAGING_DIR" | cut -f1)
DISK_SIZE=$((STAGING_SIZE + 35000))

echo "Creating writable disk image ($DISK_SIZE KB)..."
hdiutil create -srcfolder "$STAGING_DIR" -volname "$DMG_NAME" -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DISK_SIZE}k "$TEMP_DMG"

echo "Mounting disk image for layout styling..."
MOUNT_DIR=$(mktemp -d /tmp/dmg_mount_XXXXXX)
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | egrep '^/dev/' | head -n1 | awk '{print $1}')
MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | grep "/Volumes/$DMG_NAME" | awk '{print $3}')

# AppleScript to format Finder presentation
echo "Styling window layout..."
osascript << APPLESCRIPT || true
tell application "Finder"
    tell disk "$DMG_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 1060, 620}
        
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 110
        set background picture of theViewOptions to file ".background:background.png"
        
        -- Positions
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {510, 200}
        set position of item "Hızlı İşlemi Yükle.command" of container window to {330, 310}
        
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEVICE" 2>/dev/null || true

# Compress and finalize
echo "Compressing into final read-only DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DMG"

# Clean up
rm -rf "$STAGING_DIR" "$TEMP_DMG" "/tmp/dmg_background.png" "$MOUNT_DIR"

echo "🎉 Sleek DMG created successfully at: $OUTPUT_DMG"
