import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?
    var zoomEngine: ZoomEngine?
    var drawingEngine: DrawingEngine?
    
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
        
        setupHotkeys()
        requestPermissions()
        
        print("✅ LiveZoom started - automatic termination disabled")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("⚠️ applicationShouldTerminateAfterLastWindowClosed - returning false")
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("⚠️ applicationShouldTerminate - returning .terminateCancel")
        return .terminateCancel
    }
    
    func setupHotkeys() {
        hotkeyManager?.registerHotkey(key: .one, modifiers: [.command]) { [weak self] in
            self?.toggleZoomMode()
        }
        
        hotkeyManager?.registerHotkey(key: .two, modifiers: [.command]) { [weak self] in
            self?.toggleDrawMode()
        }
        
        hotkeyManager?.registerHotkey(key: .three, modifiers: [.command]) { [weak self] in
            self?.showTimer()
        }
        
        hotkeyManager?.registerHotkey(key: .four, modifiers: [.command]) { [weak self] in
            self?.toggleLiveZoom()
        }
    }
    
    func toggleZoomMode() {
        zoomEngine?.toggle()
    }
    
    func toggleDrawMode() {
        drawingEngine?.toggle()
    }
    
    func showTimer() {
        print("Timer mode - To be implemented")
    }
    
    func toggleLiveZoom() {
        print("LiveZoom mode - To be implemented")
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
