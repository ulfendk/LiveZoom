import Cocoa

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var menu: NSMenu
    
    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "viewfinder.circle", accessibilityDescription: "LiveZoom")
            button.image?.isTemplate = true
        }
        
        setupMenu()
        statusItem.menu = menu
    }
    
    private func setupMenu() {
        menu.addItem(NSMenuItem(title: "Zoom (⌘1)", action: #selector(zoomAction), keyEquivalent: "1"))
        menu.addItem(NSMenuItem(title: "Draw (⌘2)", action: #selector(drawAction), keyEquivalent: "2"))
        menu.addItem(NSMenuItem(title: "Timer (⌘3)", action: #selector(timerAction), keyEquivalent: "3"))
        menu.addItem(NSMenuItem(title: "LiveZoom (⌘4)", action: #selector(liveZoomAction), keyEquivalent: "4"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(preferencesAction), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit LiveZoom", action: #selector(quitAction), keyEquivalent: "q"))
        
        for item in menu.items {
            item.target = self
        }
    }
    
    @objc private func zoomAction() {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleZoom"), object: nil)
    }
    
    @objc private func drawAction() {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleDraw"), object: nil)
    }
    
    @objc private func timerAction() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowTimer"), object: nil)
    }
    
    @objc private func liveZoomAction() {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleLiveZoom"), object: nil)
    }
    
    @objc private func preferencesAction() {
        print("Preferences - To be implemented")
    }
    
    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
