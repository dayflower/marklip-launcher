#!/bin/bash

# generate-iconset.sh
# Generates an .iconset directory with all required icon sizes from a source PNG

set -e

SOURCE_IMAGE="Sources/MarklipLauncher/AppIcon.icon/Assets/Image.png"
ICONSET_DIR="Resources/AppIcon.iconset"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    exit 1
fi

echo "Generating iconset from $SOURCE_IMAGE..."

# Remove existing iconset if it exists
rm -rf "$ICONSET_DIR"

# Create iconset directory
mkdir -p "$ICONSET_DIR"

# Generate all required icon sizes using sips
# 16x16 and 32x32 (retina)
sips -z 16 16 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null

# 32x32 and 64x64 (retina)
sips -z 32 32 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null

# 128x128 and 256x256 (retina)
sips -z 128 128 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null

# 256x256 and 512x512 (retina)
sips -z 256 256 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null

# 512x512 and 1024x1024 (retina)
sips -z 512 512 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "Iconset generated successfully at $ICONSET_DIR"
