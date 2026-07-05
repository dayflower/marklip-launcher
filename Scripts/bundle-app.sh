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

echo "Compiling app icon (actool)..."
# The app icon is an Icon Composer document (icons/AppIcon.icon). Compile it into
# an Assets.car with actool and merge the icon keys actool emits into the bundle
# Info.plist. Requires a full Xcode (actool >= 26, Icon Composer support) —
# Command Line Tools alone will fail.
ACTOOL="$(xcrun --find actool)"
ICON_SRC="icons/AppIcon.icon"
ICON_TMP="$(mktemp -d)"
trap 'rm -rf "$ICON_TMP"' EXIT
cp -R "$ICON_SRC" "$ICON_TMP/AppIcon.icon"
mkdir -p "$ICON_TMP/out"
PARTIAL_PLIST="$ICON_TMP/assetcatalog_generated_info.plist"

# Clear any stuck actool daemon that can silently produce nothing.
killall ibtoold >/dev/null 2>&1 || true

# Icon Composer (liquid glass) icons need a macOS 26 deployment target here; this
# is intentionally separate from the app's own (macOS 13) build target. With an
# older target actool emits no icon and still exits 0.
"$ACTOOL" "$ICON_TMP/AppIcon.icon" \
  --compile "$ICON_TMP/out" \
  --output-format human-readable-text \
  --notices --warnings --errors \
  --output-partial-info-plist "$PARTIAL_PLIST" \
  --app-icon AppIcon \
  --include-all-app-icons \
  --enable-on-demand-resources NO \
  --development-region en \
  --target-device mac \
  --minimum-deployment-target 26.0 \
  --platform macosx

if [ ! -f "$ICON_TMP/out/Assets.car" ]; then
  echo "Error: actool did not generate Assets.car (app icon would be missing)" >&2
  "$ACTOOL" --version || true
  exit 1
fi

cp "$ICON_TMP/out/Assets.car" "$RESOURCES_DIR/Assets.car"
/usr/libexec/PlistBuddy -c "Merge $PARTIAL_PLIST" "$CONTENTS_DIR/Info.plist"
# Ensure the icon-name key is present even if actool's partial plist omitted it.
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$CONTENTS_DIR/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$CONTENTS_DIR/Info.plist"

echo "App Bundle created successfully at: $BUNDLE_PATH"
