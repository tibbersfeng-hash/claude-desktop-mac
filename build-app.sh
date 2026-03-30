#!/bin/bash
# Build Claude Desktop as a proper .app bundle

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="Claude Desktop.app"
APP_PATH="$PROJECT_DIR/$APP_NAME"

echo "Building Claude Desktop..."

# Build the executable
swift build -c release

# Create app bundle structure
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/release/ClaudeDesktop" "$APP_PATH/Contents/MacOS/"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_PATH/Contents/"

# Copy entitlements (for reference, not used in ad-hoc signing)
cp "$PROJECT_DIR/Resources/Entitlements.entitlements" "$APP_PATH/Contents/Resources/"

# Make executable
chmod +x "$APP_PATH/Contents/MacOS/ClaudeDesktop"

# Ad-hoc sign the app (required for macOS to run properly)
codesign --force --deep --sign - "$APP_PATH"

echo ""
echo "Build complete! App created at: $APP_PATH"
echo ""
echo "To run:"
echo "  open \"$APP_PATH\""
