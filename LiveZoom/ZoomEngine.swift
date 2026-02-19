import Cocoa
import QuartzCore

class ZoomEngine {
    private var zoomWindow: NSWindow?
    private var isZooming = false
    private var zoomLevel: CGFloat = 2.0
    private var zoomCenter: CGPoint = .zero
    private var eventMonitor: Any?
    private var screenshot: CGImage?
    private var zoomView: ZoomView?  // Keep strong reference to prevent dealloc
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(toggle), name: NSNotification.Name("ToggleZoom"), object: nil)
    }
    
    deinit {
        stopZoom()
    }
    
    @objc func toggle() {
        print("🔄 ZoomEngine.toggle() called - isZooming: \(isZooming)")
        if isZooming {
            print("📴 Stopping zoom...")
            stopZoom()
            print("✅ Zoom stopped")
        } else {
            print("📹 Starting zoom...")
            startZoom()
            print("✅ Zoom started")
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
        
        // DEBUG: Print dimensions
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        let imageWidth = CGFloat(capturedImage.width)
        let imageHeight = CGFloat(capturedImage.height)
        let backingScale = screen.backingScaleFactor
        
        print("=== Zoom Debug ===")
        print("Screen (points): \(screenWidth) x \(screenHeight)")
        print("Image (pixels): \(imageWidth) x \(imageHeight)")
        print("Backing scale: \(backingScale)")
        print("Calculated scaleX: \(imageWidth / screenWidth)")
        print("Calculated scaleY: \(imageHeight / screenHeight)")
        
        // Set initial zoom center to mouse position
        let mouseLocation = NSEvent.mouseLocation
        
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
        
        print("Initial center: \(zoomCenter)")
        print("==================")

        
        // Create fullscreen window - use custom window class to prevent it from becoming key
        let windowRect = screen.frame
        let window = NSWindow(
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
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false  // Important - we manage memory manually
        
        let contentView = ZoomView(frame: windowRect)
        contentView.screenshot = screenshot
        contentView.zoomLevel = zoomLevel
        contentView.zoomCenter = zoomCenter
        window.contentView = contentView
        
        // Keep strong reference to view
        self.zoomView = contentView
        
        // Order front without making key (since NonActivatingWindow prevents becoming key)
        window.orderFront(nil)
        
        zoomWindow = window
        isZooming = true
        
        // Set up event monitoring
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel, .keyDown, .mouseMoved, .rightMouseDown]) { [weak self] event in
            self?.handleEvent(event)
        }
    }
    
    private func stopZoom() {
        print("🛑 stopZoom() called")
        
        // Remove event monitor immediately
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            print("  - Event monitor removed")
        }
        
        // Clear state immediately
        isZooming = false
        
        // Hide window immediately
        if let window = zoomWindow {
            window.orderOut(nil)
            print("  - Window hidden")
        }
        
        // Delay cleanup to avoid animation crash
        // Let the runloop finish processing before deallocating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.zoomWindow = nil
            self?.zoomView = nil
            self?.screenshot = nil
            print("  - Delayed cleanup complete")
        }
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
        
        // Calculate visible area in IMAGE PIXELS (not screen points!)
        let visibleWidth = imageWidth / zoomLevel
        let visibleHeight = imageHeight / zoomLevel
        
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
            
            let imageWidth = CGFloat(screenshot.width)
            let imageHeight = CGFloat(screenshot.height)
            
            // Calculate visible area in IMAGE PIXELS
            let visibleWidth = imageWidth / zoomLevel
            let visibleHeight = imageHeight / zoomLevel
            
            // Re-clamp center after zoom change
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
        
        // Calculate visible area in IMAGE PIXELS
        let visibleWidth = imageWidth / zoomLevel
        let visibleHeight = imageHeight / zoomLevel
        
        // Move by 10% of visible area
        let moveAmount: CGFloat = min(visibleWidth, visibleHeight) * 0.1
        
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
    
    // Prevent animation issues that cause crashes on dealloc
    override var animationBehavior: NSWindow.AnimationBehavior {
        get { .none }
        set { }
    }
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
        
        // The image is in pixels, but the view bounds are in points
        // We need to work entirely in the image's pixel coordinate system
        let imageWidth = CGFloat(screenshot.width)
        let imageHeight = CGFloat(screenshot.height)
        
        // Calculate the scale from view points to image pixels
        let scaleToImage = imageWidth / bounds.width
        
        // Transform: center on screen, zoom, then translate to focus on zoomCenter
        // All in the view's point coordinate system
        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)
        context.scaleBy(x: zoomLevel, y: zoomLevel)
        
        // Convert zoomCenter from image pixels to view points for the translation
        let centerInPoints = CGPoint(
            x: zoomCenter.x / scaleToImage,
            y: zoomCenter.y / scaleToImage
        )
        context.translateBy(x: -centerInPoints.x, y: -centerInPoints.y)
        
        // Draw the screenshot - it will be scaled to fit the view bounds automatically
        let imageRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        context.draw(screenshot, in: imageRect)
        
        context.restoreGState()
    }
}
