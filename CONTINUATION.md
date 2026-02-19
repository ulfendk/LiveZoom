# Continuation Guide for LiveZoom Development

## Setup on Another Computer

### 1. Clone and Checkout
```bash
git clone https://github.com/ulfendk/LiveZoom.git
cd LiveZoom
git checkout feature/zoom-fixes
```

### 2. Build and Install
```bash
./launch.sh
```

### 3. Grant Permissions
After first launch, you'll need to grant permissions:
- **Accessibility**: System Settings → Privacy & Security → Accessibility → Enable LiveZoom
- **Screen Recording**: System Settings → Privacy & Security → Screen Recording → Enable LiveZoom

**Important**: Due to ad-hoc code signing (no developer certificate), permissions must be re-granted after each rebuild. See DEVELOPMENT.md for details.

### 4. Test the App
- Press `⌘1` to activate zoom mode
- Move mouse to pan around the zoomed view
- Scroll to adjust zoom level
- Press `⌘1` again to exit zoom mode
- Press `⌘2` for drawing mode (draw with mouse, ESC to exit)

## Current Status

### What's Working ✅
- Menu bar integration
- Global hotkeys (⌘1 for zoom, ⌘2 for drawing)
- Snapshot-based zoom (captures screen once, displays static image)
- Mouse panning follows cursor direction correctly
- App stays running after closing zoom window
- CMD+1 toggle works without closing app
- Dynamic retina scaling applied

### Outstanding Issues ❌
1. **Edge cropping**: Approximately 1/3 of screen edges are cropped in zoom view
   - Scaling calculation implemented: `scaleX = imageWidth / screenWidth`
   - Applied consistently across all zoom operations
   - Issue persists despite scaling fixes
   - **Next step**: Debug by logging actual values of imageWidth, screenWidth, scaleX/Y to understand the discrepancy

## Key Architecture Decisions

### Coordinate Systems
The app deals with three coordinate systems:
1. **NSEvent.mouseLocation**: Screen points, origin bottom-left, Y increases upward
2. **CGImage**: Image pixels, origin top-left, Y increases downward  
3. **CGContext**: Drawing context, origin bottom-left, but CGContext.draw() auto-flips CGImages

**Current approach**: Use screen coordinates directly without Y-flip, since CGContext.draw() handles the conversion.

### Scaling for Retina Displays
- Screen dimensions are in **points** (logical pixels)
- CGDisplayCreateImage returns **physical pixels** (2x on retina)
- **Solution**: Calculate dynamic scale: `scaleX = imageWidth / screenWidth`
- Applied in: `startZoom()`, `updateZoomCenter()`, `handleScroll()`, `handleKeyPress()`

### Window Lifecycle
- Created `NonActivatingWindow` class with `canBecomeKey = false` and `canBecomeMain = false`
- Prevents zoom window from interfering with app lifecycle
- Prevents app termination when zoom window closes

## Files to Focus On

### Primary Development Files
- **LiveZoom/ZoomEngine.swift** - Core zoom functionality
  - Lines 28-65: `startZoom()` - Initial zoom setup and coordinate conversion
  - Lines 127-168: `updateZoomCenter()` - Mouse panning with scaling
  - Lines 170-200: `handleScroll()` - Zoom level adjustment
  - Lines 202-242: `handleKeyPress()` - Arrow key panning
  - Lines 276-307: `ZoomView.draw()` - Rendering the zoomed image

### Supporting Files
- **LiveZoom/AppDelegate.swift** - App lifecycle and hotkey registration
- **LiveZoom/HotkeyManager.swift** - Global keyboard shortcuts using Carbon
- **LiveZoom/DrawingEngine.swift** - Annotation overlay (drawing mode)
- **LiveZoom/StatusBarController.swift** - Menu bar integration

## Debugging the Edge Cropping Issue

### Hypothesis
The scaling factor calculation may be incorrect or applied inconsistently. The image dimensions from CGDisplayCreateImage might not match expectations.

### Recommended Debug Steps

1. **Add logging to startZoom()** to see actual dimensions:
```swift
print("Screen: \(screen.frame.width) x \(screen.frame.height)")
print("Image: \(capturedImage.width) x \(capturedImage.height)")
print("Scale: \(scaleX) x \(scaleY)")
print("BackingScaleFactor: \(screen.backingScaleFactor)")
```

2. **Log visible area calculations** in updateZoomCenter():
```swift
print("Visible: \(visibleWidth) x \(visibleHeight)")
print("Center: \(zoomCenter)")
print("Image bounds: 0-\(imageWidth), 0-\(imageHeight)")
```

3. **Check if scale equals backingScaleFactor** - they should match on retina displays

4. **Try reverting to backingScaleFactor** instead of dynamic scaling:
```swift
// In startZoom(), updateZoomCenter(), handleScroll(), handleKeyPress():
let backingScaleFactor = screen.backingScaleFactor
zoomCenter = CGPoint(
    x: pointX * backingScaleFactor,
    y: pointY * backingScaleFactor
)
```

### Alternative Approaches to Try

1. **Use NSView coordinate system** instead of manual scaling
2. **Try CALayer with transform** instead of CGContext drawing
3. **Use NSImage instead of CGImage** for automatic coordinate handling
4. **Verify window frame** matches screen frame exactly

## Building and Testing Workflow

```bash
# Clean build
cd /Users/regin/github/LiveZoom
rm -rf ~/Library/Developer/Xcode/DerivedData/LiveZoom-*
xcodebuild clean

# Build
xcodebuild -project LiveZoom.xcodeproj -scheme LiveZoom -configuration Debug

# Install to stable location
cp -R ~/Library/Developer/Xcode/DerivedData/LiveZoom-*/Build/Products/Debug/LiveZoom.app ~/Applications/

# Launch
open ~/Applications/LiveZoom.app

# Check for errors
tail -f ~/Library/Logs/LiveZoom.log  # if logging added
```

## Permission Management

Each rebuild creates a new code signature, requiring permission re-grant:
1. Quit LiveZoom
2. Open System Settings → Privacy & Security → Screen Recording
3. Remove old LiveZoom entry
4. Open new build - it will request permission
5. Grant permission and restart app

**Production solution**: Sign with Apple Developer ID certificate ($99/year).

## Next Steps

1. **Debug edge cropping**:
   - Add logging to understand actual dimensions
   - Compare calculated scale vs backingScaleFactor
   - Verify visible area calculations

2. **Test thoroughly**:
   - Test on non-retina display
   - Test with multiple monitors
   - Test zoom levels from 1.0 to 10.0
   - Test edge cases (corners, edges)

3. **Additional features** (if base functionality works):
   - Configurable zoom level increment
   - Remember last zoom level
   - Smooth zoom animation
   - Drawing mode improvements
   - Customizable hotkeys

## Resources

- [ZoomIt for Windows](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit) - Reference implementation
- [CGDisplayCreateImage Documentation](https://developer.apple.com/documentation/coregraphics/1454852-cgdisplaycreateimage)
- [NSEvent.mouseLocation](https://developer.apple.com/documentation/appkit/nsevent/1528239-mouselocation)
- [Coordinate Systems in macOS](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html)

## Contact

For questions or to continue this work, refer to:
- This document
- Code comments in ZoomEngine.swift
- DEVELOPMENT.md for permission issues
- TROUBLESHOOTING.md for common problems
