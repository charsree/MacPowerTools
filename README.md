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

## 📦 Installation

### Install with brew (Recommended)

### 1. Add the tap
```bash
brew tap charsree/tools
```
### 2. Install the app
```bash
brew install macpowertools
```
### 3. Copy to Applications folder
```bash
cp -r /opt/homebrew/opt/macpowertools/MacPowerTools.app /Applications/
```
### 4. Launch the app
```bash
open /Applications/MacPowerTools.app
```
### 5. Grant permissions when prompted:
###    - Screen Recording permission
###    - Accessibility permission

### Build Locally (Not recommended)

1. **Clone or download this repository**
2. **Navigate to the MacPowerTools directory**
3. **Build the application**:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
4. **Create distributable app bundle** (optional):
   ```bash
   chmod +x create_apps.sh
   ./create_apps.sh
   ```

### Running the Application

**Option 1: Run from command line**
```bash
./build/MacPowerTools &
```

**Option 2: Use the app bundle**
```bash
# After running create_apps.sh
open MacPowerTools.app
```

The application will appear as a **⚡ lightning bolt icon** in your menu bar.

## 🎯 Usage

### Text Extractor
1. Press `Cmd+Shift+T` anywhere on your Mac
2. Your cursor changes to a crosshair - drag to select the text area
3. The app processes the screenshot and extracts text
4. Extracted text is automatically copied to your clipboard
5. You'll see a notification with the results

**Alternative**: Click the ⚡ menu bar icon → "Extract Text"

### Clipboard History
1. The app automatically tracks your clipboard in the background
2. Press `Cmd+Shift+V` to view your clipboard history popup
3. Click any item to copy it back to clipboard
4. For full history window, use "Show Full History Window"

**Menu Bar Access**: Click the ⚡ icon to see recent clipboard items with formatting indicators (🎨 for formatted content)

### Menu Bar Interface
The unified ⚡ menu bar icon provides access to:
- Text extraction functionality
- Recent clipboard items (last 5)
- Full clipboard history window
- Clear history option
- Quit application

## 🔒 Permissions Setup

### First Run Requirements
When you first launch Mac Power Tools, macOS will request permissions:

1. **Screen Recording Permission** (for Text Extractor)
   - System Preferences → Security & Privacy → Privacy → Screen Recording
   - Add and enable MacPowerTools

2. **Accessibility Permission** (for global hotkeys)
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Add and enable MacPowerTools

### Granting Permissions
1. Open **System Preferences** (or **System Settings** on macOS 13+)
2. Navigate to **Security & Privacy** → **Privacy**
3. Select **Screen Recording** and add MacPowerTools
4. Select **Accessibility** and add MacPowerTools
5. Restart the application after granting permissions

## 🔄 Auto-Start on Login

To launch Mac Power Tools automatically when you log in:

1. **System Preferences** → **Users & Groups** → **Login Items**
2. Click **+** and add:
   - `MacPowerTools/build/MacPowerTools` (command line version)
   - OR `MacPowerTools.app` (app bundle version)

## 🛠 Technical Details

### Architecture
- **Single Swift application** with dual functionality
- **Frameworks**: Cocoa, Vision, Carbon, AVFoundation
- **Background operation** with menu bar interface
- **Memory efficient**: < 50MB RAM usage
- **Local processing**: No internet connection required

### Text Extraction
- Uses Apple's **Vision framework** for OCR
- Supports **multiple languages** automatically
- **High accuracy** text recognition
- Integrates with macOS screenshot utility
- Processes images locally for privacy

### Clipboard Management
- **Real-time monitoring** (0.3-second intervals)
- **Rich text preservation** (RTF, HTML formatting)
- **Smart deduplication** prevents duplicate entries
- **Memory-based storage** (clears on restart)
- **Configurable history limit** (default: 50 items)

### Global Hotkeys
- **Carbon Event Manager** for system-wide shortcuts
- **Cmd+Shift+T**: Text extraction
- **Cmd+Shift+V**: Clipboard history
- **Event-driven architecture** for responsive performance

## 🔧 Build Process

### Manual Build
```bash
# Navigate to source directory
cd MacPowerTools/Sources

# Compile with required frameworks
swiftc -o ../../build/MacPowerTools main.swift \
  -framework Cocoa \
  -framework Vision \
  -framework Carbon \
  -framework AVFoundation

# Make executable
chmod +x ../../build/MacPowerTools
```

### App Bundle Creation
The `create_apps.sh` script creates a proper macOS application bundle with:
- **Info.plist** configuration
- **LSUIElement** for menu bar-only operation
- **Proper bundle structure** for distribution
- **Code signing preparation**

## 📋 Keyboard Shortcuts Reference

| Action | Shortcut | Description |
|--------|----------|-------------|
| Extract Text | `Cmd+Shift+T` | Capture screenshot and extract text |
| Clipboard History | `Cmd+Shift+V` | Show clipboard history popup |

## 🔍 Troubleshooting

### Text Extractor Issues
- **No text detected**: Ensure clear, readable text in the selected area
- **Permission denied**: Grant Screen Recording permissions
- **Hotkey not working**: Grant Accessibility permissions
- **Poor accuracy**: Try capturing larger text or better contrast

### Clipboard History Issues
- **Not tracking**: Grant Accessibility permissions and restart app
- **Hotkey not responding**: Check Accessibility permissions
- **Formatting lost**: Ensure source application supports rich text copying
- **History not showing**: Restart the application

### General Issues
- **App won't start**: Verify macOS 10.15+ and Xcode Command Line Tools
- **Build fails**: Run `xcode-select --install`
- **Menu bar icon missing**: Check if app is running in Activity Monitor
- **High CPU usage**: Restart the application

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
- **Memory**: Minimal impact (< 50MB)
- **Storage**: < 5MB application size
- **Permissions**: Screen Recording, Accessibility

## 🚀 Distribution

### For Personal Use
- Use the built executable: `./build/MacPowerTools`
- Or create app bundle: `MacPowerTools.app`

### For Sharing

**Option 1: App Bundle Only (Recommended)**
1. Run `./create_apps.sh` to create `MacPowerTools.app`
2. Compress only the `.app` bundle:
   ```bash
   zip -r MacPowerTools.zip MacPowerTools.app
   ```
3. Share the zip file with recipients
4. Include `INSTALL_INSTRUCTIONS.txt` for setup guidance

**Option 2: Source Code Distribution**
When zipping the entire project folder, **exclude these files/folders**:

```bash
# Create clean distribution zip
zip -r MacPowerTools-Source.zip MacPowerTools/ \
  -x "MacPowerTools/build/*" \
  -x "MacPowerTools/.DS_Store" \
  -x "MacPowerTools/*/.DS_Store" \
  -x "MacPowerTools/*.app/*" \
  -x "MacPowerTools/*.zip" \
  -x "MacPowerTools/*.log"
```

**Files to EXCLUDE when zipping:**
- `build/` directory (compiled executables)
- `.DS_Store` files (macOS system files)
- `*.app/` bundles (if distributing source)
- `*.zip`, `*.tar.gz` archives
- `*.log` files
- IDE files (`.vscode/`, `.idea/`)
- Temporary files (`*.tmp`, `*~`)

**Files to INCLUDE:**
- `MacPowerTools/Sources/main.swift` (source code)
- `build.sh` and `create_apps.sh` (build scripts)
- `README.md` (documentation)
- `INSTALL_INSTRUCTIONS.txt` (user guide)
- `.gitignore` (for developers)

### Distribution Tips
- **For end users**: Share only `MacPowerTools.app` in a zip
- **For developers**: Share source code without build artifacts
- **Always include**: Setup instructions and permission requirements
- **Test**: Verify the zip works on a clean Mac before sharing

## 🎉 Getting Started

1. **Build** the application using `./build.sh`
2. **Run** with `./build/MacPowerTools &`
3. **Grant permissions** when prompted
4. **Look for** the ⚡ icon in your menu bar
5. **Try** `Cmd+Shift+T` for text extraction
6. **Try** `Cmd+Shift+V` for clipboard history

---

**Enjoy your enhanced Mac productivity!** ⚡

*Mac Power Tools brings essential Windows PowerToys functionality to macOS in a single, lightweight application.*
