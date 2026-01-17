#!/bin/bash

# bundle-app.sh
# Creates an App Bundle from the Swift Package Manager executable

set -e

PRODUCT_NAME="marklip-launcher"
BUILD_DIR=".build"
RELEASE_DIR="$BUILD_DIR/release"
BUNDLE_NAME="Marklip Launcher.app"
BUNDLE_PATH="$RELEASE_DIR/$BUNDLE_NAME"
CONTENTS_DIR="$BUNDLE_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST_SOURCE="Resources/Info.plist"

echo "Building $PRODUCT_NAME..."
swift build -c release

echo "Creating App Bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "Copying executable..."
cp "$RELEASE_DIR/$PRODUCT_NAME" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"

echo "Copying Info.plist..."
cp "$INFO_PLIST_SOURCE" "$CONTENTS_DIR/Info.plist"

echo "Generating app icon..."
./Scripts/generate-iconset.sh

echo "Converting iconset to icns..."
iconutil -c icns Resources/AppIcon.iconset -o "$RESOURCES_DIR/AppIcon.icns"

echo "Cleaning up iconset..."
rm -rf Resources/AppIcon.iconset

echo "App Bundle created successfully at: $BUNDLE_PATH"
