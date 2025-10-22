#!/bin/bash

# Create proper macOS application (.app bundle)
# This script creates a single distributable application that can be shared with friends

echo "📦 Creating macOS Application Bundle..."

# Kill existing processes and remove old app
pkill MacPowerTools 2>/dev/null || true
rm -rf "MacPowerTools.app" 2>/dev/null || true

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
    <string>2.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
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
echo "   📝 Text Extractor: Customizable hotkeys (default Cmd+Shift+T)"
echo "   📋 Clipboard History: Customizable hotkeys (default Cmd+Shift+V)"
echo "   🎛️ Custom Hotkeys: Configure via Preferences menu"
echo "   🔐 Smart Permissions: Only requested when needed"
echo "   🚀 Login Items: Easy management via menu bar"
echo ""
echo "🚀 Usage:"
echo "   1. Double-click MacPowerTools.app to launch"
echo "   2. App runs in background with ⌬ menu bar icon"
echo "   3. To share: Just copy the .app file to other Macs"
echo ""
echo "💡 Menu Bar Features:"
echo "   • Text extraction and clipboard history"
echo "   • Custom hotkey preferences"
echo "   • Login items management"
echo "   • Clean, no-popup startup"
echo ""
echo "🎛️ Custom Hotkeys:"
echo "   Click ⌬ menu bar icon → Preferences to customize hotkeys"
echo "   Supports: cmd, shift, alt/option, ctrl/control + any letter a-z"
