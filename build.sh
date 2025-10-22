#!/bin/bash

# Build script for Mac Power Tools
# This script compiles the combined Mac Power Tools application

set -e

echo "🔨 Building Mac Power Tools..."

# Kill existing processes
pkill MacPowerTools 2>/dev/null || true

# Remove existing app from Applications
if [ -d "/Applications/MacPowerTools.app" ]; then
    echo "🗑️ Removing existing MacPowerTools.app from Applications..."
    rm -rf "/Applications/MacPowerTools.app"
fi

# Create build directory
mkdir -p build

# Build Combined Mac Power Tools
echo "⌬ Building Mac Power Tools (Combined App)..."
cd MacPowerTools/Sources
swiftc -o ../../build/MacPowerTools main.swift -framework Cocoa -framework Vision -framework Carbon -framework AVFoundation
cd ../..

# Make executable
chmod +x build/MacPowerTools

if [ $? -eq 0 ]; then
    echo "✅ Build complete!"
    echo ""
    echo "📍 Executable created in build/ directory:"
    echo "   • MacPowerTools - Combined Text Extractor + Clipboard History"
    echo ""
    echo "🚀 Features:"
    echo "   📝 Text Extractor: Customizable hotkeys (default Cmd+Shift+T)"
    echo "   📋 Clipboard History: Customizable hotkeys (default Cmd+Shift+V)"
    echo "   🎛️ Custom Hotkeys: Configurable via Preferences menu"
    echo "   🚀 Login Items: Easy add/remove via menu bar"
    echo ""
    echo "🚀 To run:"
    echo "   ./build/MacPowerTools &"
    echo ""
    echo "💡 Single app with ⌬ menu bar icon for both features"
else
    echo "❌ Build failed!"
    exit 1
fi


