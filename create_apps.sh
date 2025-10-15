#!/bin/bash

# Create proper macOS application (.app bundle)
# This script creates a single distributable application that can be shared with friends

echo "📦 Creating macOS Application Bundle..."

# Create MacPowerTools.app
echo "⌬ Creating MacPowerTools.app..."
mkdir -p "MacPowerTools.app/Contents/MacOS"
mkdir -p "MacPowerTools.app/Contents/Resources"

# Copy executable
cp "build/MacPowerTools" "MacPowerTools.app/Contents/MacOS/MacPowerTools"
chmod +x "MacPowerTools.app/Contents/MacOS/MacPowerTools"

# Copy icon if it exists
if [ -f "MacPowerTools.icns" ]; then
    cp "MacPowerTools.icns" "MacPowerTools.app/Contents/Resources/"
    echo "🎨 Added app icon"
fi

# Create Info.plist for MacPowerTools
cat > "MacPowerTools.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacPowerTools</string>
    <key>CFBundleIdentifier</key>
    <string>com.macpowertools.macpowertools</string>
    <key>CFBundleName</key>
    <string>Mac Power Tools</string>
    <key>CFBundleDisplayName</key>
    <string>Mac Power Tools</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>MPWT</string>
    <key>CFBundleIconFile</key>
    <string>MacPowerTools</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2025 Mac Power Tools</string>
</dict>
</plist>
EOF

echo "✅ Application bundle created!"
echo ""
echo "📍 Created Application:"
echo "   • MacPowerTools.app - Double-click to run"
echo ""
echo "🚀 Features in one app:"
echo "   📝 Text Extractor: Cmd+Shift+T to extract text from screenshots"
echo "   📋 Clipboard History: Cmd+Shift+V to view clipboard history with formatting"
echo ""
echo "🚀 Usage:"
echo "   1. Double-click MacPowerTools.app to launch"
echo "   2. App runs in background with ⚡ menu bar icon"
echo "   3. To share: Just copy the .app file to other Macs"
echo ""
echo "💡 Auto-start setup:"
echo "   System Preferences → Users & Groups → Login Items"
echo "   Add MacPowerTools.app to start automatically on login"
echo ""
echo "🔒 First run permissions:"
echo "   System Preferences → Security & Privacy → Privacy"
echo "   - Add MacPowerTools.app to 'Accessibility'"
echo "   - Add MacPowerTools.app to 'Screen Recording'"
