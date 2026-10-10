#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT="$DIR/iConverter.xcodeproj"
ARCHIVE_PATH="$DIR/build/iConverter.xcarchive"

echo "📦 Archiving iConverter for Mac App Store with Xcode..."

# Clean previous archive
rm -rf "$ARCHIVE_PATH"

# Create App Store Archive
xcodebuild archive \
  -project "$PROJECT" \
  -scheme iConverter \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH"

echo "✅ Arşiv başarıyla oluşturuldu: $ARCHIVE_PATH"
echo "🚀 Şimdi Xcode Organizer açılıyor. 'Distribute App' butonuna basarak tek tıkla App Store Connect'e yükleyebilirsiniz!"

open "$ARCHIVE_PATH"
