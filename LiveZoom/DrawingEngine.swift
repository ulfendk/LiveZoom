import Cocoa

class DrawingEngine {
    private var drawWindow: NSWindow?
    private var isDrawing = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(toggle), name: NSNotification.Name("ToggleDraw"), object: nil)
    }
    
    deinit {
        stopDrawing()
    }
    
    @objc func toggle() {
        if isDrawing {
            stopDrawing()
        } else {
            startDrawing()
        }
    }
    
    private func startDrawing() {
        guard let screen = NSScreen.main else { return }
        
        let windowRect = screen.frame
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .statusBar
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        
        let contentView = DrawingView(frame: windowRect)
        window.contentView = contentView
        
        window.makeKeyAndOrderFront(nil)
        
        drawWindow = window
        isDrawing = true
    }
    
    private func stopDrawing() {
        // Clear state immediately
        isDrawing = false
        
        // Hide window immediately
        if let window = drawWindow {
            window.orderOut(nil)
        }
        
        // Delay cleanup to avoid animation crash (same as ZoomEngine)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.drawWindow = nil
        }
    }
}

class DrawingView: NSView {
    private var paths: [(path: NSBezierPath, color: NSColor)] = []
    private var currentPath: NSBezierPath?
    private var penColor: NSColor = .red
    private var penWidth: CGFloat = 3.0
    private var eventMonitor: Any?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupEventMonitors()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupEventMonitors() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .keyDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            
            switch event.type {
            case .leftMouseDown:
                self.startDrawing(at: self.convert(event.locationInWindow, from: nil))
                return nil
            case .leftMouseDragged:
                self.continueDrawing(to: self.convert(event.locationInWindow, from: nil))
                return nil
            case .leftMouseUp:
                self.endDrawing()
                return nil
            case .keyDown:
                if event.keyCode == 53 { // Escape
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleDraw"), object: nil)
                    return nil
                } else if event.characters?.lowercased() == "e" {
                    self.clearAll()
                    return nil
                } else if event.characters?.lowercased() == "r" {
                    self.penColor = .red
                    return nil
                } else if event.characters?.lowercased() == "g" {
                    self.penColor = .green
                    return nil
                } else if event.characters?.lowercased() == "b" {
                    self.penColor = .blue
                    return nil
                } else if event.characters?.lowercased() == "y" {
                    self.penColor = .yellow
                    return nil
                } else if event.keyCode == 51 { // Delete
                    self.undo()
                    return nil
                }
            case .rightMouseDown:
                NotificationCenter.default.post(name: NSNotification.Name("ToggleDraw"), object: nil)
                return nil
            default:
                break
            }
            
            return event
        }
    }
    
    private func startDrawing(at point: NSPoint) {
        currentPath = NSBezierPath()
        currentPath?.lineWidth = penWidth
        currentPath?.move(to: point)
    }
    
    private func continueDrawing(to point: NSPoint) {
        currentPath?.line(to: point)
        needsDisplay = true
    }
    
    private func endDrawing() {
        if let path = currentPath {
            paths.append((path: path, color: penColor))
        }
        currentPath = nil
    }
    
    private func undo() {
        if !paths.isEmpty {
            paths.removeLast()
            needsDisplay = true
        }
    }
    
    private func clearAll() {
        paths.removeAll()
        currentPath = nil
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        for (path, color) in paths {
            color.setStroke()
            path.stroke()
        }
        
        if let currentPath = currentPath {
            penColor.setStroke()
            currentPath.stroke()
        }
    }
}
