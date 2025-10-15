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
        checkAndRequestPermissions()
        setupStatusBar()
        registerGlobalHotkeys()
        startClipboardMonitoring()
        print("Mac Power Tools started!")
        print("📝 Text Extractor: Press Cmd+Shift+T")
        print("📋 Clipboard History: Press Cmd+Shift+V")
    }
    
    func checkAndRequestPermissions() {
        // Check Screen Recording permission
        let screenRecordingGranted = CGPreflightScreenCaptureAccess()
        if !screenRecordingGranted {
            showNotification(title: "Permission Required", message: "Please grant Screen Recording permission in System Preferences")
            CGRequestScreenCaptureAccess()
        }
        
        // Check Accessibility permission
        let accessibilityGranted = AXIsProcessTrusted()
        if !accessibilityGranted {
            showNotification(title: "Permission Required", message: "Please grant Accessibility permission in System Preferences")
            
            // Request accessibility permission
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        
        if !screenRecordingGranted || !accessibilityGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showPermissionAlert()
            }
        }
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permissions Required"
        alert.informativeText = "Mac Power Tools needs:\n\n• Screen Recording (for text extraction)\n• Accessibility (for global hotkeys and pasting)\n\nPlease grant these permissions in System Preferences and restart the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create attributed string with baseline offset
        let attributedTitle = NSAttributedString(string: "⌬", attributes: [
            .font: NSFont.systemFont(ofSize: 24),
            .baselineOffset: -2
        ])
        
        statusItem?.button?.attributedTitle = attributedTitle
        statusItem?.button?.toolTip = "Mac Power Tools - Cmd+Shift+T (Text) | Cmd+Shift+V (Clipboard)"
        
        updateStatusBarMenu()
    }
    
    func registerGlobalHotkeys() {
        // Register Text Extractor hotkey (Cmd+Shift+T)
        var textHotKeyID = EventHotKeyID()
        textHotKeyID.signature = fourCharCodeFrom("TXTE")
        textHotKeyID.id = 1
        
        let textModifiers = UInt32(cmdKey | shiftKey)
        let textKeyCode = UInt32(kVK_ANSI_T)
        
        let textStatus = RegisterEventHotKey(textKeyCode, textModifiers, textHotKeyID, GetApplicationEventTarget(), 0, &textExtractorHotKeyRef)
        if textStatus != noErr {
            print("Failed to register Text Extractor hotkey. Status: \(textStatus)")
        } else {
            print("Successfully registered Cmd+Shift+T for Text Extractor")
        }
        
        // Register Clipboard History hotkey (Cmd+Shift+V)
        var clipHotKeyID = EventHotKeyID()
        clipHotKeyID.signature = fourCharCodeFrom("CLIP")
        clipHotKeyID.id = 2
        
        let clipModifiers = UInt32(cmdKey | shiftKey)
        let clipKeyCode = UInt32(kVK_ANSI_V)
        
        let clipStatus = RegisterEventHotKey(clipKeyCode, clipModifiers, clipHotKeyID, GetApplicationEventTarget(), 0, &clipboardHistoryHotKeyRef)
        if clipStatus != noErr {
            print("Failed to register Clipboard History hotkey. Status: \(clipStatus)")
        } else {
            print("Successfully registered Cmd+Shift+V for Clipboard History")
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
        menu.addItem(NSMenuItem(title: "   Extract Text (Cmd+Shift+T)", action: #selector(captureAndExtractText), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Clipboard History section
        menu.addItem(NSMenuItem(title: "Clipboard History", action: nil, keyEquivalent: ""))
        
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
                menu.addItem(NSMenuItem(title: "   Show All History (Cmd+Shift+V)", action: #selector(showClipboardHistory), keyEquivalent: ""))
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear Clipboard History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
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
