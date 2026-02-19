#!/bin/bash

# Build and launch LiveZoom with consistent app bundle location

set -e

echo "Building LiveZoom..."
xcodebuild -project LiveZoom.xcodeproj -scheme LiveZoom -configuration Debug build > /dev/null 2>&1

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "LiveZoom.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find LiveZoom.app"
    exit 1
fi

# Copy to a consistent location to help with permissions
INSTALL_DIR="$HOME/Applications"
INSTALL_PATH="$INSTALL_DIR/LiveZoom.app"

mkdir -p "$INSTALL_DIR"

# Remove old version if exists
if [ -d "$INSTALL_PATH" ]; then
    echo "Removing old version..."
    rm -rf "$INSTALL_PATH"
fi

echo "Installing to $INSTALL_PATH..."
cp -R "$APP_PATH" "$INSTALL_PATH"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  LiveZoom installed to: $INSTALL_PATH"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "IMPORTANT: Screen Recording Permission"
echo ""
echo "Because this is a development build (ad-hoc signing),"
echo "you need to grant Screen Recording permission:"
echo ""
echo "1. Open System Settings"
echo "2. Privacy & Security → Screen Recording"
echo "3. Look for 'LiveZoom' in the list"
echo "4. Enable the checkbox"
echo ""
echo "Note: You may need to remove old entries and re-add"
echo "      the app if you've rebuilt it."
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Launching LiveZoom..."
echo ""
echo "Usage:"
echo "  • Press ⌘1 to activate Zoom mode"
echo "  • Press ⌘2 to activate Drawing mode"
echo "  • Click the viewfinder icon in menu bar for options"
echo ""

open "$INSTALL_PATH"
