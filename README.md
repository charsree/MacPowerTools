# Mac Power Tools ⌬

A powerful macOS utility that enhances your productivity with advanced screen text extraction and intelligent clipboard management.

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

## 📋 Keyboard Shortcuts Reference

| Action | Default Shortcut | Description |
|--------|----------|-------------|
| Extract Text | `Cmd+Shift+T` | Capture screenshot and extract text |
| Clipboard History | `Cmd+Shift+V` | Show clipboard history and paste selected item |

### 🎛️ Custom Hotkeys
You can customize both hotkeys through the **Preferences** menu:
1. Click the ⌬ icon in your menu bar
2. Select **"Preferences..."**
3. Modify the hotkey combinations in the text fields
4. Click **"Save"** to apply changes immediately

**Supported modifiers**: `cmd`, `shift`, `alt`/`option`, `ctrl`/`control`
**Supported keys**: Any letter `a-z`
**Examples**: `cmd+alt+t`, `ctrl+shift+v`, `cmd+option+s`

The menu bar will automatically update to show your current hotkey combinations.

## 📦 Quick Installation (Recommended)

### 1. Install with Homebrew
```bash
# Add the tap
brew tap charsree/tools

# Install the app
brew install macpowertools

# Copy to Applications and launch (works on Intel and Apple Silicon)
cp -r $(brew --prefix)/opt/macpowertools/MacPowerTools.app /Applications/
open /Applications/MacPowerTools.app
```

**If you get SHA256 errors when updating:**
```bash
# Refresh the tap and try again
brew untap charsree/tools
brew tap charsree/tools
brew install macpowertools
```

### 2. Grant Permissions (When Needed)
Mac Power Tools uses a **smart permission system**:
  - **Screen Recording**: When you first use text extraction (Cmd+Shift+T)
  - **Accessibility**: When you first use clipboard history (Cmd+Shift+V)

**That's it!** The app will appear as a **⌬ diamond icon** in your menu bar.

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
4. Items with [F] indicator have rich formatting preserved

### Menu Bar Interface
Click the ⌬ icon to access:
- Text extraction functionality
- Recent clipboard items (last 5)
- Full clipboard history window
- Clear history option
- **Custom hotkey preferences**
- **Login items management**

## 🔒 Permissions

### Screen Recording Permission
- **Purpose**: Capture screenshots for text extraction
- **When requested**: When you first use Cmd+Shift+T (or custom hotkey)
- **System dialog**: macOS shows standard permission request

### Accessibility Permission  
- **Purpose**: Global hotkeys and auto-paste functionality
- **When requested**: When you first use Cmd+Shift+V (or custom hotkey)
- **System dialog**: macOS shows standard permission request

## 🚀 Login Items Management

**Easy Management**: Built into the menu bar
1. Click the ⌬ icon in your menu bar
2. Select **"Add to Login Items..."** or **"Remove from Login Items"**
3. Menu automatically updates based on current status

**Manual Setup** (alternative):
1. **System Preferences** → **Users & Groups** → **Login Items**
2. Click **+** and add `/Applications/MacPowerTools.app`

## 🛠 Manual Build

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

- **Operating System**: macOS 10.15 or later
- **Architecture**: Intel x64 or Apple Silicon (Universal)
- **Memory**: < 50MB RAM usage
- **Storage**: < 5MB application size
- **Permissions**: Screen Recording, Accessibility (requested automatically)

## 🎉 Getting Started

1. **Install**: Use Homebrew or build manually
2. **Launch**: Open `/Applications/MacPowerTools.app`
3. **Grant permissions**: Follow the automatic prompts
4. **Look for**: The ⌬ icon in your menu bar
5. **Try**: `Cmd+Shift+T` for text extraction
6. **Try**: `Cmd+Shift+V` for clipboard history with auto-paste

---

**Enjoy your enhanced Mac productivity!** ⚡

*Mac Power Tools brings essential productivity enhancements to macOS with automatic setup and seamless integration.*
