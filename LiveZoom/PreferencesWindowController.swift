import Cocoa
import ServiceManagement

class PreferencesWindowController: NSWindowController {
    private var accessibilityStatusLabel: NSTextField!
    private var screenRecordingStatusLabel: NSTextField!
    private var launchAtLoginCheckbox: NSButton!
    private var autoUpdateCheckbox: NSButton!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LiveZoom Preferences"
        window.center()
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let window = window else { return }
        
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView
        
        var yPos: CGFloat = window.frame.height - 60
        
        // MARK: - Permissions Section
        let permissionsLabel = NSTextField(labelWithString: "Permissions")
        permissionsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        permissionsLabel.frame = NSRect(x: 20, y: yPos, width: 460, height: 20)
        contentView.addSubview(permissionsLabel)
        yPos -= 30
        
        // Accessibility permission
        let accessibilityLabel = NSTextField(labelWithString: "Accessibility:")
        accessibilityLabel.frame = NSRect(x: 40, y: yPos, width: 120, height: 20)
        contentView.addSubview(accessibilityLabel)
        
        accessibilityStatusLabel = NSTextField(labelWithString: checkAccessibilityPermission() ? "✓ Granted" : "✗ Not Granted")
        accessibilityStatusLabel.frame = NSRect(x: 170, y: yPos, width: 120, height: 20)
        accessibilityStatusLabel.textColor = checkAccessibilityPermission() ? .systemGreen : .systemRed
        contentView.addSubview(accessibilityStatusLabel)
        
        let accessibilityButton = NSButton(title: "Open Settings", target: self, action: #selector(openAccessibilitySettings))
        accessibilityButton.frame = NSRect(x: 300, y: yPos - 3, width: 150, height: 25)
        accessibilityButton.bezelStyle = .rounded
        contentView.addSubview(accessibilityButton)
        yPos -= 30
        
        // Screen Recording permission
        let screenRecordingLabel = NSTextField(labelWithString: "Screen Recording:")
        screenRecordingLabel.frame = NSRect(x: 40, y: yPos, width: 120, height: 20)
        contentView.addSubview(screenRecordingLabel)
        
        screenRecordingStatusLabel = NSTextField(labelWithString: checkScreenRecordingPermission() ? "✓ Granted" : "✗ Not Granted")
        screenRecordingStatusLabel.frame = NSRect(x: 170, y: yPos, width: 120, height: 20)
        screenRecordingStatusLabel.textColor = checkScreenRecordingPermission() ? .systemGreen : .systemRed
        contentView.addSubview(screenRecordingStatusLabel)
        
        let screenRecordingButton = NSButton(title: "Open Settings", target: self, action: #selector(openScreenRecordingSettings))
        screenRecordingButton.frame = NSRect(x: 300, y: yPos - 3, width: 150, height: 25)
        screenRecordingButton.bezelStyle = .rounded
        contentView.addSubview(screenRecordingButton)
        yPos -= 40
        
        // Separator
        let separator1 = NSBox(frame: NSRect(x: 20, y: yPos, width: 460, height: 1))
        separator1.boxType = .separator
        contentView.addSubview(separator1)
        yPos -= 30
        
        // MARK: - General Settings Section
        let generalLabel = NSTextField(labelWithString: "General")
        generalLabel.font = NSFont.boldSystemFont(ofSize: 14)
        generalLabel.frame = NSRect(x: 20, y: yPos, width: 460, height: 20)
        contentView.addSubview(generalLabel)
        yPos -= 30
        
        // Launch at Login
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch LiveZoom at login", target: self, action: #selector(toggleLaunchAtLogin(_:)))
        launchAtLoginCheckbox.frame = NSRect(x: 40, y: yPos, width: 400, height: 20)
        launchAtLoginCheckbox.state = isLaunchAtLoginEnabled() ? .on : .off
        contentView.addSubview(launchAtLoginCheckbox)
        yPos -= 40
        
        // Separator
        let separator2 = NSBox(frame: NSRect(x: 20, y: yPos, width: 460, height: 1))
        separator2.boxType = .separator
        contentView.addSubview(separator2)
        yPos -= 30
        
        // MARK: - Updates Section
        let updatesLabel = NSTextField(labelWithString: "Updates")
        updatesLabel.font = NSFont.boldSystemFont(ofSize: 14)
        updatesLabel.frame = NSRect(x: 20, y: yPos, width: 460, height: 20)
        contentView.addSubview(updatesLabel)
        yPos -= 30
        
        // Auto-update checkbox
        autoUpdateCheckbox = NSButton(checkboxWithTitle: "Automatically check for updates", target: self, action: #selector(toggleAutoUpdate(_:)))
        autoUpdateCheckbox.frame = NSRect(x: 40, y: yPos, width: 400, height: 20)
        autoUpdateCheckbox.state = UpdateManager.shared.isAutoUpdateEnabled() ? .on : .off
        contentView.addSubview(autoUpdateCheckbox)
        yPos -= 30
        
        // Check now button
        let checkNowButton = NSButton(title: "Check for Updates Now", target: self, action: #selector(checkForUpdatesNow))
        checkNowButton.frame = NSRect(x: 40, y: yPos, width: 200, height: 25)
        checkNowButton.bezelStyle = .rounded
        contentView.addSubview(checkNowButton)
        
        // Current version label
        let versionLabel = NSTextField(labelWithString: "Current version: \(UpdateManager.shared.getCurrentVersion())")
        versionLabel.frame = NSRect(x: 250, y: yPos + 3, width: 200, height: 20)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        contentView.addSubview(versionLabel)
    }
    
    // MARK: - Permission Checking
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        guard let mainScreen = NSScreen.main else { return false }
        let displayID = mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        
        // Try to create a small screenshot - if it fails, we don't have permission
        if let image = CGDisplayCreateImage(displayID, rect: CGRect(x: 0, y: 0, width: 1, height: 1)) {
            return image.width > 0
        }
        return false
    }
    
    // MARK: - Permission Actions
    
    @objc private func openAccessibilitySettings() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
        
        // Refresh status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updatePermissionStatus()
        }
    }
    
    @objc private func openScreenRecordingSettings() {
        // Open System Settings to Privacy & Security > Screen Recording
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
        
        // Refresh status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updatePermissionStatus()
        }
    }
    
    private func updatePermissionStatus() {
        let hasAccessibility = checkAccessibilityPermission()
        accessibilityStatusLabel.stringValue = hasAccessibility ? "✓ Granted" : "✗ Not Granted"
        accessibilityStatusLabel.textColor = hasAccessibility ? .systemGreen : .systemRed
        
        let hasScreenRecording = checkScreenRecordingPermission()
        screenRecordingStatusLabel.stringValue = hasScreenRecording ? "✓ Granted" : "✗ Not Granted"
        screenRecordingStatusLabel.textColor = hasScreenRecording ? .systemGreen : .systemRed
    }
    
    // MARK: - Launch at Login
    
    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older macOS versions, check UserDefaults as fallback
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        let enable = sender.state == .on
        
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                print("Launch at login \(enable ? "enabled" : "disabled")")
            } catch {
                print("Failed to \(enable ? "enable" : "disable") launch at login: \(error)")
                sender.state = enable ? .off : .on // Revert checkbox
                
                let alert = NSAlert()
                alert.messageText = "Failed to update launch at login"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } else {
            // For older macOS versions, just save preference
            UserDefaults.standard.set(enable, forKey: "launchAtLogin")
            print("Launch at login preference saved: \(enable)")
            
            let alert = NSAlert()
            alert.messageText = "macOS 13+ Required"
            alert.informativeText = "Launch at login requires macOS 13 or later. Your preference has been saved but won't take effect."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // MARK: - Auto-update
    
    @objc private func toggleAutoUpdate(_ sender: NSButton) {
        let enable = sender.state == .on
        UpdateManager.shared.setAutoUpdateEnabled(enable)
        print("Auto-update \(enable ? "enabled" : "disabled")")
    }
    
    @objc private func checkForUpdatesNow() {
        UpdateManager.shared.checkForUpdates(userInitiated: true)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Refresh permission status when window is shown
        updatePermissionStatus()
    }
}
