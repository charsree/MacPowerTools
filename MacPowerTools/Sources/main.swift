#!/usr/bin/env swift

import Cocoa
import Vision
import Carbon
import AVFoundation

class MacPowerToolsApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var clipboardHistory: [ClipboardItem] = []
    var lastClipboardChangeCount: Int = 0
    var timer: Timer?
    var textExtractorHotKeyRef: EventHotKeyRef?
    var clipboardHistoryHotKeyRef: EventHotKeyRef?
    let maxHistoryItems = 50
    var isPasting = false
    
    // Hotkey preferences
    var textExtractorKey: String {
        get { UserDefaults.standard.string(forKey: "textExtractorKey") ?? "t" }
        set { UserDefaults.standard.set(newValue, forKey: "textExtractorKey") }
    }
    var textExtractorModifiers: String {
        get { UserDefaults.standard.string(forKey: "textExtractorModifiers") ?? "cmd+shift" }
        set { UserDefaults.standard.set(newValue, forKey: "textExtractorModifiers") }
    }
    var clipboardKey: String {
        get { UserDefaults.standard.string(forKey: "clipboardKey") ?? "v" }
        set { UserDefaults.standard.set(newValue, forKey: "clipboardKey") }
    }
    var clipboardModifiers: String {
        get { UserDefaults.standard.string(forKey: "clipboardModifiers") ?? "cmd+shift" }
        set { UserDefaults.standard.set(newValue, forKey: "clipboardModifiers") }
    }
    
    struct ClipboardItem {
        let content: String
        let rtfData: Data?
        let htmlData: Data?
        let timestamp: Date
        let preview: String
        let hasFormatting: Bool
        
        init(content: String, rtfData: Data? = nil, htmlData: Data? = nil) {
            self.content = content
            self.rtfData = rtfData
            self.htmlData = htmlData
            self.timestamp = Date()
            self.hasFormatting = rtfData != nil || htmlData != nil
            
            // Create preview (first 50 characters) with formatting indicator
            let basePreview = String(content.prefix(50)).replacingOccurrences(of: "\n", with: " ")
            self.preview = hasFormatting ? "[F] \(basePreview)" : basePreview
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        registerGlobalHotkeys()
        startClipboardMonitoring()
        print("Mac Power Tools started!")
        print("📝 Text Extractor: Press Cmd+Shift+T")
        print("📋 Clipboard History: Press Cmd+Shift+V")
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create attributed string with baseline offset
        let attributedTitle = NSAttributedString(string: "⌬", attributes: [
            .font: NSFont.systemFont(ofSize: 24),
            .baselineOffset: -2
        ])
        
        statusItem?.button?.attributedTitle = attributedTitle
        statusItem?.button?.toolTip = "Mac Power Tools - \(textExtractorModifiers.replacingOccurrences(of: "+", with: "+").capitalized)+\(textExtractorKey.uppercased()) (Text) | \(clipboardModifiers.replacingOccurrences(of: "+", with: "+").capitalized)+\(clipboardKey.uppercased()) (Clipboard)"
        
        // Add target-action to refresh menu when clicked
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(statusBarClicked)
        
        updateStatusBarMenu()
    }
    
    @objc func statusBarClicked() {
        updateStatusBarMenu()
        statusItem?.popUpMenu(statusItem!.menu!)
    }
    
    func registerGlobalHotkeys() {
        // Unregister existing hotkeys
        if let textRef = textExtractorHotKeyRef {
            UnregisterEventHotKey(textRef)
        }
        if let clipRef = clipboardHistoryHotKeyRef {
            UnregisterEventHotKey(clipRef)
        }
        
        // Register Text Extractor hotkey
        var textHotKeyID = EventHotKeyID()
        textHotKeyID.signature = fourCharCodeFrom("TXTE")
        textHotKeyID.id = 1
        
        let textModifiers = parseModifiers(textExtractorModifiers)
        let textKeyCode = parseKeyCode(textExtractorKey)
        
        let textStatus = RegisterEventHotKey(textKeyCode, textModifiers, textHotKeyID, GetApplicationEventTarget(), 0, &textExtractorHotKeyRef)
        if textStatus != noErr {
            print("Failed to register Text Extractor hotkey. Status: \(textStatus)")
        } else {
            print("Successfully registered \(textExtractorModifiers)+\(textExtractorKey) for Text Extractor")
        }
        
        // Register Clipboard History hotkey
        var clipHotKeyID = EventHotKeyID()
        clipHotKeyID.signature = fourCharCodeFrom("CLIP")
        clipHotKeyID.id = 2
        
        let clipModifiers = parseModifiers(clipboardModifiers)
        let clipKeyCode = parseKeyCode(clipboardKey)
        
        let clipStatus = RegisterEventHotKey(clipKeyCode, clipModifiers, clipHotKeyID, GetApplicationEventTarget(), 0, &clipboardHistoryHotKeyRef)
        if clipStatus != noErr {
            print("Failed to register Clipboard History hotkey. Status: \(clipStatus)")
        } else {
            print("Successfully registered \(clipboardModifiers)+\(clipboardKey) for Clipboard History")
        }
        
        // Install event handler for both hotkeys
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            let app = Unmanaged<MacPowerToolsApp>.fromOpaque(userData!).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            DispatchQueue.main.async {
                if hotKeyID.id == 1 { // Text Extractor
                    app.captureAndExtractText()
                } else if hotKeyID.id == 2 { // Clipboard History
                    app.showClipboardHistory()
                }
            }
            
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)
        
        if installStatus != noErr {
            print("Failed to install event handler. Status: \(installStatus)")
        }
    }
    
    // MARK: - Clipboard History Functions
    
    func startClipboardMonitoring() {
        lastClipboardChangeCount = NSPasteboard.general.changeCount
        
        // Add initial clipboard content if any
        if let initialContent = NSPasteboard.general.string(forType: .string),
           !initialContent.isEmpty {
            let rtfData = NSPasteboard.general.data(forType: .rtf)
            let htmlData = NSPasteboard.general.data(forType: .html)
            addToHistoryWithFormatting(initialContent, rtfData: rtfData, htmlData: htmlData)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    func checkClipboardChanges() {
        if isPasting { return }
        
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastClipboardChangeCount {
            lastClipboardChangeCount = currentChangeCount
            
            if let clipboardString = pasteboard.string(forType: .string),
               !clipboardString.isEmpty,
               clipboardString.count < 10000 {
                
                let rtfData = pasteboard.data(forType: .rtf)
                let htmlData = pasteboard.data(forType: .html)
                
                addToHistoryWithFormatting(clipboardString, rtfData: rtfData, htmlData: htmlData)
                
                let formatInfo = (rtfData != nil || htmlData != nil) ? " (with formatting)" : ""
                print("Added to clipboard history: \(String(clipboardString.prefix(50)))\(formatInfo)...")
            }
        }
    }
    
    func addToHistoryWithFormatting(_ content: String, rtfData: Data?, htmlData: Data?) {
        if let lastItem = clipboardHistory.first, lastItem.content == content {
            return
        }
        
        let newItem = ClipboardItem(content: content, rtfData: rtfData, htmlData: htmlData)
        clipboardHistory.insert(newItem, at: 0)
        
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryItems))
        }
        
        updateStatusBarMenu()
    }
    
    @objc func showClipboardHistory() {
        if clipboardHistory.isEmpty {
            showNotification(title: "Clipboard History", message: "No clipboard history available yet")
            return
        }
        
        let menu = NSMenu()
        
        for (index, item) in clipboardHistory.prefix(15).enumerated() {
            let menuItem = NSMenuItem(title: "\(index + 1). \(item.preview)", action: #selector(selectClipboardItemFromPopup(_:)), keyEquivalent: "")
            menuItem.tag = index
            menuItem.toolTip = item.content
            menu.addItem(menuItem)
        }
        
        if clipboardHistory.count > 15 {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Show Full History Window", action: #selector(showFullHistoryWindow), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
        
        let mouseLocation = NSEvent.mouseLocation
        menu.popUp(positioning: nil, at: mouseLocation, in: nil)
    }
    
    @objc func selectClipboardItemFromPopup(_ sender: NSMenuItem) {
        let index = sender.tag
        if index < clipboardHistory.count {
            let item = clipboardHistory[index]
            
            isPasting = true
            copyToClipboardWithFormatting(item)
            lastClipboardChangeCount = NSPasteboard.general.changeCount
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.simulatePaste()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isPasting = false
                }
            }
            
            let formatInfo = item.hasFormatting ? " (with formatting)" : ""
            showNotification(title: "Pasted", message: "Pasted: \(item.preview)\(formatInfo)")
        }
    }
    
    // MARK: - Text Extractor Functions
    
    @objc func captureAndExtractText() {
        // Check permission first, request if needed
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
            showNotification(title: "Permission Required", message: "Please grant Screen Recording permission and restart the app")
            return
        }
        
        captureScreenshot { [weak self] image in
            guard let image = image else {
                self?.showNotification(title: "Error", message: "Failed to capture screenshot")
                return
            }
            
            self?.extractTextFromImage(image) { text in
                if !text.isEmpty {
                    self?.copyToClipboard(text)
                    self?.showNotification(title: "Text Extracted", message: "Copied \(text.count) characters to clipboard")
                } else {
                    self?.showNotification(title: "No Text Found", message: "No text detected in the screenshot")
                }
            }
        }
    }
    
    func captureScreenshot(completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.main.async {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-i", "-c", "-x"]
            
            task.terminationHandler = { _ in
                DispatchQueue.main.async {
                    let pasteboard = NSPasteboard.general
                    if let imageData = pasteboard.data(forType: .tiff),
                       let image = NSImage(data: imageData) {
                        completion(image)
                    } else {
                        completion(nil)
                    }
                }
            }
            
            task.launch()
        }
    }
    
    func extractTextFromImage(_ image: NSImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n")
            DispatchQueue.main.async {
                completion(fullText)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    // MARK: - Menu and UI Functions
    
    func updateStatusBarMenu() {
        let menu = NSMenu()
        
        // Text Extractor section
        menu.addItem(NSMenuItem(title: "Text Extractor", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "   Extract Text (\(textExtractorModifiers.replacingOccurrences(of: "+", with: "+").capitalized)+\(textExtractorKey.uppercased()))", action: #selector(captureAndExtractText), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Clipboard History section
        menu.addItem(NSMenuItem(title: "Clipboard History (\(clipboardModifiers.replacingOccurrences(of: "+", with: "+").capitalized)+\(clipboardKey.uppercased()))", action: nil, keyEquivalent: ""))
        
        if clipboardHistory.isEmpty {
            menu.addItem(NSMenuItem(title: "   No clipboard history", action: nil, keyEquivalent: ""))
        } else {
            for (index, item) in clipboardHistory.prefix(5).enumerated() {
                let menuItem = NSMenuItem(title: "   \(index + 1). \(item.preview)", action: #selector(selectClipboardItem(_:)), keyEquivalent: "")
                menuItem.tag = index
                menuItem.toolTip = item.content
                menu.addItem(menuItem)
            }
            
            if clipboardHistory.count > 5 {
                menu.addItem(NSMenuItem(title: "   Show All History (\(clipboardModifiers.replacingOccurrences(of: "+", with: "+").capitalized)+\(clipboardKey.uppercased()))", action: #selector(showClipboardHistory), keyEquivalent: ""))
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear Clipboard History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        // Login items menu
        if isInLoginItems() {
            menu.addItem(NSMenuItem(title: "Remove from Login Items", action: #selector(removeFromLoginItems), keyEquivalent: ""))
        } else {
            menu.addItem(NSMenuItem(title: "Add to Login Items...", action: #selector(openLoginItemsSettings), keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit Mac Power Tools", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func selectClipboardItem(_ sender: NSMenuItem) {
        let index = sender.tag
        if index < clipboardHistory.count {
            let item = clipboardHistory[index]
            copyToClipboardWithFormatting(item)
            let formatInfo = item.hasFormatting ? " (with formatting)" : ""
            showNotification(title: "Clipboard Updated", message: "Copied: \(item.preview)\(formatInfo)")
        }
    }
    
    @objc func showFullHistoryWindow() {
        let window = createHistoryWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func createHistoryWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Mac Power Tools - Clipboard History"
        window.center()
        
        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        
        let tableView = NSTableView()
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("time"))
        column1.title = "Time"
        column1.width = 120
        
        let column2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        column2.title = "Content"
        column2.width = 450
        
        tableView.addTableColumn(column1)
        tableView.addTableColumn(column2)
        
        let dataSource = ClipboardHistoryDataSource(history: clipboardHistory)
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        
        // Store the data source in the window to prevent deallocation
        objc_setAssociatedObject(window, "dataSource", dataSource, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        tableView.doubleAction = #selector(ClipboardHistoryDataSource.doubleClickAction(_:))
        tableView.target = dataSource
        
        scrollView.documentView = tableView
        window.contentView?.addSubview(scrollView)
        
        // Reload the table data
        tableView.reloadData()
        
        return window
    }
    
    @objc func clearHistory() {
        clipboardHistory.removeAll()
        updateStatusBarMenu()
        showNotification(title: "History Cleared", message: "Clipboard history has been cleared")
    }
    
    @objc func openLoginItemsSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
    }
    
    func isInLoginItems() -> Bool {
        let script = """
        tell application "System Events"
            set loginItemNames to name of every login item
            return loginItemNames contains "MacPowerTools"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(nil)
            let isPresent = result.booleanValue
            print("DEBUG: Login items check - MacPowerTools present: \(isPresent)")
            return isPresent
        }
        print("DEBUG: AppleScript failed")
        return false
    }
    
    @objc func removeFromLoginItems() {
        let script = """
        tell application "System Events"
            delete every login item whose path contains "MacPowerTools"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if error == nil {
                showNotification(title: "Removed from Login Items", message: "Mac Power Tools will not start automatically")
                updateStatusBarMenu()
            }
        }
    }
    
    @objc func showPreferences() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                             styleMask: [.titled, .closable],
                             backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "Mac Power Tools Preferences"
        window.center()
        
        let contentView = NSView(frame: window.contentView!.bounds)
        
        // Text Extractor settings
        let textLabel = NSTextField(labelWithString: "Text Extractor Hotkey:")
        textLabel.frame = NSRect(x: 20, y: 220, width: 150, height: 20)
        contentView.addSubview(textLabel)
        
        let textModField = NSTextField(frame: NSRect(x: 180, y: 220, width: 100, height: 20))
        textModField.stringValue = textExtractorModifiers
        textModField.isEditable = true
        textModField.isSelectable = true
        textModField.isBezeled = true
        textModField.bezelStyle = .squareBezel
        textModField.tag = 1
        contentView.addSubview(textModField)
        
        let textKeyField = NSTextField(frame: NSRect(x: 290, y: 220, width: 50, height: 20))
        textKeyField.stringValue = textExtractorKey
        textKeyField.isEditable = true
        textKeyField.isSelectable = true
        textKeyField.isBezeled = true
        textKeyField.bezelStyle = .squareBezel
        textKeyField.tag = 2
        contentView.addSubview(textKeyField)
        
        // Clipboard settings
        let clipLabel = NSTextField(labelWithString: "Clipboard History Hotkey:")
        clipLabel.frame = NSRect(x: 20, y: 180, width: 150, height: 20)
        contentView.addSubview(clipLabel)
        
        let clipModField = NSTextField(frame: NSRect(x: 180, y: 180, width: 100, height: 20))
        clipModField.stringValue = clipboardModifiers
        clipModField.isEditable = true
        clipModField.isSelectable = true
        clipModField.isBezeled = true
        clipModField.bezelStyle = .squareBezel
        clipModField.tag = 3
        contentView.addSubview(clipModField)
        
        let clipKeyField = NSTextField(frame: NSRect(x: 290, y: 180, width: 50, height: 20))
        clipKeyField.stringValue = clipboardKey
        clipKeyField.isEditable = true
        clipKeyField.isSelectable = true
        clipKeyField.isBezeled = true
        clipKeyField.bezelStyle = .squareBezel
        clipKeyField.tag = 4
        contentView.addSubview(clipKeyField)
        
        // Help text
        let helpLabel = NSTextField(labelWithString: "Format: 'cmd+shift', 'cmd+alt', 'ctrl+shift', etc.")
        helpLabel.frame = NSRect(x: 20, y: 140, width: 360, height: 20)
        helpLabel.textColor = .secondaryLabelColor
        contentView.addSubview(helpLabel)
        
        // Buttons
        let saveButton = NSButton(frame: NSRect(x: 220, y: 20, width: 80, height: 30))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(savePreferences(_:))
        contentView.addSubview(saveButton)
        
        let cancelButton = NSButton(frame: NSRect(x: 310, y: 20, width: 80, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(closePreferences(_:))
        contentView.addSubview(cancelButton)
        
        window.contentView = contentView
        window.level = .modalPanel
        window.orderFrontRegardless()
        window.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func savePreferences(_ sender: NSButton) {
        guard let window = sender.window,
              let contentView = window.contentView else { return }
        
        for subview in contentView.subviews {
            if let textField = subview as? NSTextField {
                switch textField.tag {
                case 1: textExtractorModifiers = textField.stringValue
                case 2: textExtractorKey = textField.stringValue
                case 3: clipboardModifiers = textField.stringValue
                case 4: clipboardKey = textField.stringValue
                default: break
                }
            }
        }
        
        registerGlobalHotkeys()
        updateStatusBarMenu()
        window.close()
        showNotification(title: "Preferences Saved", message: "Hotkeys updated successfully")
    }
    
    @objc func closePreferences(_ sender: NSButton) {
        sender.window?.close()
    }
    
    func parseModifiers(_ modString: String) -> UInt32 {
        var mods: UInt32 = 0
        let parts = modString.lowercased().components(separatedBy: "+")
        for part in parts {
            switch part.trimmingCharacters(in: .whitespaces) {
            case "cmd", "command": mods |= UInt32(cmdKey)
            case "shift": mods |= UInt32(shiftKey)
            case "alt", "option": mods |= UInt32(optionKey)
            case "ctrl", "control": mods |= UInt32(controlKey)
            default: break
            }
        }
        return mods
    }
    
    func parseKeyCode(_ key: String) -> UInt32 {
        switch key.lowercased() {
        case "a": return UInt32(kVK_ANSI_A)
        case "b": return UInt32(kVK_ANSI_B)
        case "c": return UInt32(kVK_ANSI_C)
        case "d": return UInt32(kVK_ANSI_D)
        case "e": return UInt32(kVK_ANSI_E)
        case "f": return UInt32(kVK_ANSI_F)
        case "g": return UInt32(kVK_ANSI_G)
        case "h": return UInt32(kVK_ANSI_H)
        case "i": return UInt32(kVK_ANSI_I)
        case "j": return UInt32(kVK_ANSI_J)
        case "k": return UInt32(kVK_ANSI_K)
        case "l": return UInt32(kVK_ANSI_L)
        case "m": return UInt32(kVK_ANSI_M)
        case "n": return UInt32(kVK_ANSI_N)
        case "o": return UInt32(kVK_ANSI_O)
        case "p": return UInt32(kVK_ANSI_P)
        case "q": return UInt32(kVK_ANSI_Q)
        case "r": return UInt32(kVK_ANSI_R)
        case "s": return UInt32(kVK_ANSI_S)
        case "t": return UInt32(kVK_ANSI_T)
        case "u": return UInt32(kVK_ANSI_U)
        case "v": return UInt32(kVK_ANSI_V)
        case "w": return UInt32(kVK_ANSI_W)
        case "x": return UInt32(kVK_ANSI_X)
        case "y": return UInt32(kVK_ANSI_Y)
        case "z": return UInt32(kVK_ANSI_Z)
        default: return UInt32(kVK_ANSI_T) // fallback
        }
    }
    
    // MARK: - Utility Functions
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func copyToClipboardWithFormatting(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        pasteboard.setString(item.content, forType: .string)
        
        if let rtfData: Data = item.rtfData {
            pasteboard.setData(rtfData, forType: .rtf)
        }
        
        if let htmlData: Data = item.htmlData {
            pasteboard.setData(htmlData, forType: .html)
        }
    }
    
    func simulatePaste() {
        let cmdVDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let cmdVUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        
        cmdVDown?.flags = .maskCommand
        cmdVUp?.flags = .maskCommand
        
        cmdVDown?.post(tap: .cghidEventTap)
        cmdVUp?.post(tap: .cghidEventTap)
    }
    
    func showNotification(title: String, message: String) {
        if #available(macOS 11.0, *) {
            print("Notification: \(title) - \(message)")
        } else {
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
}

class ClipboardHistoryDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let history: [MacPowerToolsApp.ClipboardItem]
    let dateFormatter: DateFormatter
    
    init(history: [MacPowerToolsApp.ClipboardItem]) {
        self.history = history
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .none
        self.dateFormatter.timeStyle = .short
        super.init()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return history.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let item = history[row]
        
        if tableColumn?.identifier.rawValue == "time" {
            return dateFormatter.string(from: item.timestamp)
        } else {
            return item.preview
        }
    }
    
    @objc func doubleClickAction(_ sender: NSTableView) {
        let selectedRow = sender.selectedRow
        if selectedRow >= 0 && selectedRow < history.count {
            let item: MacPowerToolsApp.ClipboardItem = history[selectedRow]
            
            if let appDelegate = NSApplication.shared.delegate as? MacPowerToolsApp {
                appDelegate.copyToClipboardWithFormatting(item)
                
                let formatInfo = item.hasFormatting ? " (with formatting)" : ""
                if #available(macOS 11.0, *) {
                    print("Notification: Copied to Clipboard - \(item.preview)\(formatInfo)")
                } else {
                    let notification = NSUserNotification()
                    notification.title = "Copied to Clipboard"
                    notification.informativeText = "\(item.preview)\(formatInfo)"
                    NSUserNotificationCenter.default.deliver(notification)
                }
            }
        }
    }
}

// Helper function
func fourCharCodeFrom(_ string: String) -> FourCharCode {
    assert(string.count == 4)
    var result: FourCharCode = 0
    for char in string.utf16 {
        result = (result << 8) + FourCharCode(char)
    }
    return result
}

// Main application setup
let app = NSApplication.shared
let delegate = MacPowerToolsApp()
app.delegate = delegate
app.run()
