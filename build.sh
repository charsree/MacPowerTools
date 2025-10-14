#!/bin/bash

# Build script for Mac Power Tools
# This script compiles the combined Mac Power Tools application

set -e

echo "🔨 Building Mac Power Tools..."

# Create build directory
mkdir -p build

# Build Combined Mac Power Tools
echo "⚡ Building Mac Power Tools (Combined App)..."
cd MacPowerTools/Sources
swiftc -o ../../build/MacPowerTools main.swift -framework Cocoa -framework Vision -framework Carbon -framework AVFoundation
cd ../..

# Make executable
chmod +x build/MacPowerTools

echo "✅ Build complete!"
echo ""
echo "📍 Executable created in build/ directory:"
echo "   • MacPowerTools - Combined Text Extractor + Clipboard History"
echo ""
echo "🚀 Features:"
echo "   📝 Text Extractor: Press Cmd+Shift+T to extract text from screenshots"
echo "   📋 Clipboard History: Press Cmd+Shift+V to view clipboard history with formatting"
echo ""
echo "🚀 To run:"
echo "   ./build/MacPowerTools &"
echo ""
echo "💡 Single app with ⚡ menu bar icon for both features"
