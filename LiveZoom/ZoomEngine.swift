import Cocoa
import QuartzCore

class ZoomEngine {
    private var zoomWindow: NSWindow?
    private var isZooming = false
    private var zoomLevel: CGFloat = 2.0
    private var zoomCenter: CGPoint = .zero
    private var eventMonitor: Any?
    private var screenshot: CGImage?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(toggle), name: NSNotification.Name("ToggleZoom"), object: nil)
    }
    
    deinit {
        stopZoom()
    }
    
    @objc func toggle() {
        if isZooming {
            stopZoom()
        } else {
            startZoom()
        }
    }
    
    private func startZoom() {
        // Prevent starting if already zooming
        if isZooming {
            return
        }
        
        guard let screen = NSScreen.main else { return }
        
        // Capture screen ONCE before showing zoom window
        let displayID = CGMainDisplayID()
        guard let capturedImage = CGDisplayCreateImage(displayID) else {
            showPermissionAlert()
            return
        }
        
        screenshot = capturedImage
        
        // Set initial zoom center to mouse position
        let mouseLocation = NSEvent.mouseLocation
        
        let imageWidth = CGFloat(capturedImage.width)
        let imageHeight = CGFloat(capturedImage.height)
        
        // Convert screen points to image coordinates
        // The captured image dimensions should match screen dimensions
        let pointX = mouseLocation.x - screen.frame.origin.x
        let pointY = mouseLocation.y - screen.frame.origin.y
        
        // Scale to image pixel coordinates
        let scaleX = imageWidth / screen.frame.width
        let scaleY = imageHeight / screen.frame.height
        
        zoomCenter = CGPoint(
            x: pointX * scaleX,
            y: pointY * scaleY
        )
        
        // Create fullscreen window - use custom window class to prevent it from becoming key
        let windowRect = screen.frame
        let window = NonActivatingWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.setFrameOrigin(NSPoint(x: screen.frame.origin.x, y: screen.frame.origin.y))
        window.level = .statusBar
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let contentView = ZoomView(frame: windowRect)
        contentView.screenshot = screenshot
        contentView.zoomLevel = zoomLevel
        contentView.zoomCenter = zoomCenter
        window.contentView = contentView
        
        window.makeKeyAndOrderFront(nil)
        
        zoomWindow = window
        isZooming = true
        
        // Set up event monitoring
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel, .keyDown, .mouseMoved, .rightMouseDown]) { [weak self] event in
            self?.handleEvent(event)
        }
    }
    
    private func stopZoom() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        zoomWindow?.close()
        zoomWindow = nil
        screenshot = nil
        isZooming = false
    }
    
    private func handleEvent(_ event: NSEvent) {
        guard isZooming else { return }
        
        switch event.type {
        case .scrollWheel:
            handleScroll(event)
        case .keyDown:
            if event.keyCode == 53 { // Escape
                toggle()
            } else {
                handleKeyPress(event)
            }
        case .rightMouseDown:
            toggle()
        case .mouseMoved:
            updateZoomCenter()
        default:
            break
        }
    }
    
    private func updateZoomCenter() {
        guard let screen = NSScreen.main else { return }
        guard let contentView = zoomWindow?.contentView as? ZoomView else { return }
        guard let screenshot = screenshot else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        let imageWidth = CGFloat(screenshot.width)
        let imageHeight = CGFloat(screenshot.height)
        
        // Calculate scale from screen points to image pixels
        let scaleX = imageWidth / screen.frame.width
        let scaleY = imageHeight / screen.frame.height
        
        // Convert screen points to image pixels
        let pointX = mouseLocation.x - screen.frame.origin.x
        let pointY = mouseLocation.y - screen.frame.origin.y
        
        var newCenter = CGPoint(
            x: pointX * scaleX,
            y: pointY * scaleY
        )
        
        // Calculate visible area in pixels
        let viewWidthPixels = screen.frame.width * scaleX
        let viewHeightPixels = screen.frame.height * scaleY
        
        let visibleWidth = viewWidthPixels / zoomLevel
        let visibleHeight = viewHeightPixels / zoomLevel
        
        // Clamp to ensure we never show black bars
        newCenter.x = max(visibleWidth / 2, min(newCenter.x, imageWidth - visibleWidth / 2))
        newCenter.y = max(visibleHeight / 2, min(newCenter.y, imageHeight - visibleHeight / 2))
        
        zoomCenter = newCenter
        contentView.zoomCenter = zoomCenter
        contentView.needsDisplay = true
    }
    
    private func handleScroll(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }
        guard let screenshot = screenshot else { return }
        
        let oldZoomLevel = zoomLevel
        zoomLevel += event.scrollingDeltaY * 0.1
        zoomLevel = max(1.0, min(zoomLevel, 20.0))
        
        if let contentView = zoomWindow?.contentView as? ZoomView {
            contentView.zoomLevel = zoomLevel
            
            // Calculate scale from screen to image
            let imageWidth = CGFloat(screenshot.width)
            let imageHeight = CGFloat(screenshot.height)
            let scaleX = imageWidth / screen.frame.width
            let scaleY = imageHeight / screen.frame.height
            
            // After zoom change, re-clamp the center to prevent black bars
            let viewWidthPixels = screen.frame.width * scaleX
            let viewHeightPixels = screen.frame.height * scaleY
            
            let visibleWidth = viewWidthPixels / zoomLevel
            let visibleHeight = viewHeightPixels / zoomLevel
            
            zoomCenter.x = max(visibleWidth / 2, min(zoomCenter.x, imageWidth - visibleWidth / 2))
            zoomCenter.y = max(visibleHeight / 2, min(zoomCenter.y, imageHeight - visibleHeight / 2))
            
            contentView.zoomCenter = zoomCenter
            contentView.needsDisplay = true
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }
        guard let screenshot = screenshot else { return }
        
        let imageWidth = CGFloat(screenshot.width)
        let imageHeight = CGFloat(screenshot.height)
        let scaleX = imageWidth / screen.frame.width
        let scaleY = imageHeight / screen.frame.height
        
        // Calculate visible area in pixels
        let viewWidthPixels = screen.frame.width * scaleX
        let viewHeightPixels = screen.frame.height * scaleY
        
        let visibleWidth = viewWidthPixels / zoomLevel
        let visibleHeight = viewHeightPixels / zoomLevel
        
        // Move by fixed amount
        let moveAmount: CGFloat = 50
        
        switch event.keyCode {
        case 126: // Up
            zoomCenter.y -= moveAmount
        case 125: // Down
            zoomCenter.y += moveAmount
        case 123: // Left
            zoomCenter.x -= moveAmount
        case 124: // Right
            zoomCenter.x += moveAmount
        default:
            return
        }
        
        // Clamp to prevent black bars
        zoomCenter.x = max(visibleWidth / 2, min(zoomCenter.x, imageWidth - visibleWidth / 2))
        zoomCenter.y = max(visibleHeight / 2, min(zoomCenter.y, imageHeight - visibleHeight / 2))
        
        if let contentView = zoomWindow?.contentView as? ZoomView {
            contentView.zoomCenter = zoomCenter
            contentView.needsDisplay = true
        }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Screen Recording Permission Issue"
            alert.informativeText = """
            LiveZoom needs Screen Recording permission to capture screen content.
            
            IMPORTANT FOR DEVELOPMENT BUILDS:
            Because this is built with ad-hoc code signing (no developer certificate), 
            macOS treats each rebuild as a "new" app and forgets the permission.
            
            Each time you rebuild, you must:
            1. Open System Settings → Privacy & Security → Screen Recording
            2. Remove the old LiveZoom entry (if present)
            3. Add the new LiveZoom build
            4. Grant permission
            
            For production use, sign the app with a Developer ID certificate.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "OK")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// Custom window class that prevents activation to avoid app termination issues
class NonActivatingWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class ZoomView: NSView {
    var zoomLevel: CGFloat = 2.0
    var zoomCenter: CGPoint = .zero
    var screenshot: CGImage?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        guard let screenshot = screenshot else {
            // Draw error message
            context.setFillColor(NSColor.black.cgColor)
            context.fill(bounds)
            
            let message = "Failed to capture screen.\nPlease grant Screen Recording permission."
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 18),
                .paragraphStyle: paragraphStyle
            ]
            let attrString = NSAttributedString(string: message, attributes: attrs)
            let textRect = NSRect(x: 100, y: bounds.height / 2 - 50, width: bounds.width - 200, height: 100)
            attrString.draw(in: textRect)
            return
        }
        
        // Fill background with black
        context.setFillColor(NSColor.black.cgColor)
        context.fill(bounds)
        
        context.saveGState()
        
        // Transform: center on screen, zoom, then translate to focus on zoomCenter
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)
        context.scaleBy(x: zoomLevel, y: zoomLevel)
        context.translateBy(x: -zoomCenter.x, y: -zoomCenter.y)
        
        // Draw the screenshot
        let imageRect = CGRect(x: 0, y: 0, width: CGFloat(screenshot.width), height: CGFloat(screenshot.height))
        context.draw(screenshot, in: imageRect)
        
        context.restoreGState()
        
        // Draw crosshair on top
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2)
        let crosshairSize: CGFloat = 20
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        context.move(to: CGPoint(x: centerX - crosshairSize, y: centerY))
        context.addLine(to: CGPoint(x: centerX + crosshairSize, y: centerY))
        context.move(to: CGPoint(x: centerX, y: centerY - crosshairSize))
        context.addLine(to: CGPoint(x: centerX, y: centerY + crosshairSize))
        context.strokePath()
    }
}
