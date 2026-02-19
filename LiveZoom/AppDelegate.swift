import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?
    var zoomEngine: ZoomEngine?
    var drawingEngine: DrawingEngine?
    var preferencesWindowController: PreferencesWindowController?
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable automatic termination completely
        NSApplication.shared.disableRelaunchOnLogin()
        ProcessInfo.processInfo.disableAutomaticTermination("LiveZoom is a menu bar app")
        ProcessInfo.processInfo.disableSuddenTermination()
        
        // Set as accessory app (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        statusBarController = StatusBarController()
        hotkeyManager = HotkeyManager()
        zoomEngine = ZoomEngine()
        drawingEngine = DrawingEngine()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleZoom"), object: nil, queue: .main) { [weak self] _ in
            self?.toggleZoomMode()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleDraw"), object: nil, queue: .main) { [weak self] _ in
            self?.toggleDrawMode()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowPreferences"), object: nil, queue: .main) { [weak self] _ in
            self?.showPreferences()
        }
        
        setupHotkeys()
        requestPermissions()
        
        // Start auto-update checks if enabled
        UpdateManager.shared.startAutoUpdateCheck()
        
        print("✅ LiveZoom started - automatic termination disabled")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("⚠️ applicationShouldTerminateAfterLastWindowClosed - returning false")
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("⚠️ applicationShouldTerminate - returning .terminateNow")
        return .terminateNow
    }
    
    func setupHotkeys() {
        hotkeyManager?.registerHotkey(key: .one, modifiers: [.command]) { [weak self] in
            self?.toggleZoomMode()
        }
        
        hotkeyManager?.registerHotkey(key: .two, modifiers: [.command]) { [weak self] in
            self?.toggleDrawMode()
        }
    }
    
    func toggleZoomMode() {
        zoomEngine?.toggle()
    }
    
    func toggleDrawMode() {
        drawingEngine?.toggle()
    }
    
    func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
    }
    
    func requestPermissions() {
        // Check accessibility permission silently first
        let accessEnabled = AXIsProcessTrusted()
        
        if !accessEnabled {
            // Only prompt if not already granted
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options)
            print("⚠️ Please enable Accessibility permissions for LiveZoom in System Settings")
        } else {
            print("✅ Accessibility permission granted")
        }
        
        // Screen Recording permission is checked when zoom is first activated
        // macOS will prompt automatically on first capture attempt
    }
}
