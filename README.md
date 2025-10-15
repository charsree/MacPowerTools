# Mac Power Tools ⚡

A powerful macOS utility that brings Windows PowerToys-like functionality to your Mac in a single, unified application.

## 🚀 Features

**Mac Power Tools** combines two essential productivity features in one lightweight menu bar application:

### 📝 Text Extractor
- **Keyboard Shortcut**: `Cmd+Shift+T`
- Capture any area of your screen and extract text using Apple's Vision framework
- Automatically copies extracted text to clipboard
- Supports multiple languages with automatic detection
- Shows notifications with extraction results
- High accuracy OCR processing

### 📋 Clipboard History with Formatting
- **Keyboard Shortcut**: `Cmd+Shift+V`
- Tracks up to 50 clipboard items automatically
- **Preserves rich text formatting** (RTF, HTML)
- Quick access to recent items via menu bar
- Full history window with timestamps
- Smart preview with formatting indicators
- Double-click to restore items with original formatting
- **Auto-paste functionality** - select an item to paste it immediately

## 📦 Quick Installation (Recommended)

### 1. Install with Homebrew
```bash
# Add the tap
brew tap charsree/tools

# Install the app
brew install macpowertools

# Copy to Applications and launch
cp -r /opt/homebrew/opt/macpowertools/MacPowerTools.app /Applications/
open /Applications/MacPowerTools.app
```

### 2. Grant Permissions (Automatic)
When you first launch the app, it will automatically:
- Request **Screen Recording** permission (for text extraction)
- Request **Accessibility** permission (for global hotkeys and pasting)
- Show a dialog to guide you through the permission setup

**That's it!** The app will appear as a **⚡ lightning bolt icon** in your menu bar.

## 🎯 Usage

### Text Extractor
1. Press `Cmd+Shift+T` anywhere on your Mac
2. Your cursor changes to a crosshair - drag to select the text area
3. The app processes the screenshot and extracts text
4. Extracted text is automatically copied to your clipboard
5. You'll see a notification with the results

### Clipboard History
1. The app automatically tracks your clipboard in the background
2. Press `Cmd+Shift+V` to view your clipboard history popup
3. **Click any item to paste it immediately** where your cursor is
4. Items with 🎨 indicator have rich formatting preserved

### Menu Bar Interface
Click the ⚡ icon to access:
- Text extraction functionality
- Recent clipboard items (last 5)
- Full clipboard history window
- Clear history option

## 🔒 Permissions (Handled Automatically)

The app will automatically request these permissions on first launch:

### Screen Recording Permission
- **Purpose**: Capture screenshots for text extraction
- **When prompted**: Click "Allow" or go to System Preferences → Privacy & Security → Screen Recording

### Accessibility Permission  
- **Purpose**: Global hotkeys (`Cmd+Shift+T`, `Cmd+Shift+V`) and auto-paste functionality
- **When prompted**: Click "Allow" or go to System Preferences → Privacy & Security → Accessibility

**Important**: After granting permissions, restart the app for full functionality.

## 🔄 Auto-Start Setup

To make Mac Power Tools start automatically when you log in:

**Option 1: Automatic (when installing via Homebrew)**
The app automatically adds itself to login items.

**Option 2: Manual Setup**
1. **System Preferences** → **Users & Groups** → **Login Items**
2. Click **+** and add `/Applications/MacPowerTools.app`

## 🛠 Manual Build (Advanced Users)

### Prerequisites
- macOS 10.15+ with Xcode Command Line Tools
- Swift compiler available

### Build Steps
```bash
# Clone the repository
git clone https://github.com/charsree/MacPowerTools.git
cd MacPowerTools

# Build the application
chmod +x build.sh
./build.sh

# Create app bundle
chmod +x create_apps.sh
./create_apps.sh

# Copy to Applications
cp -r MacPowerTools.app /Applications/
open /Applications/MacPowerTools.app
```

## 📋 Keyboard Shortcuts Reference

| Action | Shortcut | Description |
|--------|----------|-------------|
| Extract Text | `Cmd+Shift+T` | Capture screenshot and extract text |
| Clipboard History | `Cmd+Shift+V` | Show clipboard history and paste selected item |

## 🔍 Troubleshooting

### Common Issues

**App doesn't respond to hotkeys**
- Grant Accessibility permission in System Preferences
- Restart the app after granting permissions

**Text extraction not working**
- Grant Screen Recording permission in System Preferences
- Ensure you're selecting clear, readable text

**Clipboard items don't paste**
- Ensure Accessibility permission is granted
- The app needs this permission to simulate `Cmd+V` keypress

**App not starting automatically**
- Check System Preferences → Users & Groups → Login Items
- Add `/Applications/MacPowerTools.app` if missing

### Permission Reset
If permissions seem broken:
```bash
# Reset permissions (requires admin password)
sudo tccutil reset ScreenCapture com.macpowertools.app
sudo tccutil reset Accessibility com.macpowertools.app

# Restart the app
pkill MacPowerTools
open /Applications/MacPowerTools.app
```

## 🔐 Privacy & Security

Mac Power Tools:
- **Processes all data locally** on your Mac
- **No network connections** or data transmission
- **No persistent storage** (clipboard history is memory-only)
- **Respects system permissions** and security boundaries
- **Open source** - you can review all code

## 📊 System Requirements

- **Operating System**: macOS 10.15 (Catalina) or later
- **Architecture**: Intel x64 or Apple Silicon (Universal)
- **Memory**: < 50MB RAM usage
- **Storage**: < 5MB application size
- **Permissions**: Screen Recording, Accessibility (requested automatically)

## 🎉 Getting Started

1. **Install**: Use Homebrew or build manually
2. **Launch**: Open `/Applications/MacPowerTools.app`
3. **Grant permissions**: Follow the automatic prompts
4. **Look for**: The ⚡ icon in your menu bar
5. **Try**: `Cmd+Shift+T` for text extraction
6. **Try**: `Cmd+Shift+V` for clipboard history with auto-paste

---

**Enjoy your enhanced Mac productivity!** ⚡

*Mac Power Tools brings essential Windows PowerToys functionality to macOS with automatic setup and seamless integration.*
