# LiveZoom

A macOS screen zoom, annotation, and presentation tool inspired by ZoomIt for Windows.

## ⚠️ NB! First-Time Setup

When you first run LiveZoom (especially if built locally or downloaded), macOS Gatekeeper may prevent it from opening with a message like *"LiveZoom.app cannot be opened because it is from an unidentified developer"*.

**To authorize the app:**

1. **Locate the app** in Finder (usually in `~/Applications/` or `/Applications/`)
2. **Right-click (or Control-click)** on `LiveZoom.app`
3. Select **"Open"** from the context menu
4. In the dialog that appears, click **"Open"** again to confirm
5. The app will now run and be authorized for future launches

Alternatively, you can authorize it via System Settings:
1. Go to **System Settings** → **Privacy & Security**
2. Scroll down to find the message about LiveZoom being blocked
3. Click **"Open Anyway"**
4. Confirm by clicking **"Open"** in the dialog

After this one-time authorization, LiveZoom will launch normally in the future.

## Features

### Currently Implemented ✅

- **Zoom Mode (⌘1)**: Magnify any area of your screen
  - Takes a snapshot when activated
  - Move mouse to pan around the zoomed snapshot
  - Scroll or use arrow keys to zoom in/out
  - Arrow keys to pan manually
  - Crosshair indicator shows zoom center
  - Panning stops at screen edges
  - Press Escape or right-click to exit

- **Drawing Mode (⌘2)**: Annotate your screen in real-time
  - Freehand drawing with mouse
  - Multiple pen colors: R (red), G (green), B (blue), Y (yellow)
  - Delete key to undo last drawing
  - E key to clear all drawings
  - Press Escape or right-click to exit

- **Menu Bar Integration**: Runs unobtrusively from the macOS menu bar
- **Global Hotkeys**: Access features from anywhere with keyboard shortcuts
- **Accessibility Support**: Automatically requests necessary permissions

## Installation

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/LiveZoom.git
   cd LiveZoom
   ```

2. Open the project in Xcode:
   ```bash
   open LiveZoom.xcodeproj
   ```

3. Build and run (⌘R) or create an archive for distribution

### First Run

On first launch, LiveZoom will request necessary permissions:

1. **Accessibility Permission** - Required for:
   - Global hotkey functionality
   - Keyboard event monitoring

2. **Screen Recording Permission** - Required for:
   - Capturing screen content for zoom
   - Live screen magnification

To grant permissions:
1. Go to **System Settings** → **Privacy & Security**
2. Enable LiveZoom in **Accessibility**
3. Enable LiveZoom in **Screen Recording**
4. Restart LiveZoom after granting permissions

## Usage

### Keyboard Shortcuts

| Shortcut | Function |
|----------|----------|
| ⌘1 | Toggle Zoom Mode |
| ⌘2 | Toggle Drawing Mode |
| ⌘3 | Show Timer (coming soon) |
| ⌘4 | Toggle LiveZoom Mode (coming soon) |
| ⌘Q | Quit LiveZoom |

### In Zoom Mode

| Key/Action | Function |
|------------|----------|
| Mouse Movement | Pan around the zoomed snapshot |
| Scroll Up / ↑ | Zoom In |
| Scroll Down / ↓ | Zoom Out |
| Arrow Keys | Pan view manually |
| Escape / Right-Click | Exit Zoom Mode |

**Note**: Zoom displays a snapshot of your screen taken when you activate it (not live video).

### In Drawing Mode

| Key | Function |
|-----|----------|
| Left Mouse | Draw freehand |
| R | Red pen |
| G | Green pen |
| B | Blue pen |
| Y | Yellow pen |
| Delete | Undo last drawing |
| E | Erase all drawings |
| Escape / Right-Click | Exit Drawing Mode |

## Architecture

LiveZoom is built using:
- **Swift 5.0** - Modern, safe programming language
- **SwiftUI + AppKit** - Hybrid approach for menu bar app
- **Core Graphics** - Screen capture and drawing
- **Quartz Display Services** - Screen magnification
- **Carbon Events** - Global hotkey registration

### Project Structure

```
LiveZoom/
├── LiveZoomApp.swift          # App entry point
├── AppDelegate.swift          # App lifecycle and coordination
├── StatusBarController.swift  # Menu bar integration
├── HotkeyManager.swift        # Global hotkey registration
├── ZoomEngine.swift           # Screen magnification engine
├── DrawingEngine.swift        # Annotation and drawing engine
├── Info.plist                 # App configuration
└── LiveZoom.entitlements      # macOS permissions
```

## Privacy & Security

LiveZoom respects your privacy:
- All operations are performed locally on your Mac
- No data is sent to external servers
- Screen captures stay on your device
- Accessibility permissions are used only for hotkey functionality and screen access

## Roadmap

- [ ] Advanced drawing tools (shapes, arrows)
- [ ] Text annotation
- [ ] Screenshot and screen recording
- [ ] Presenter timer
- [ ] Preferences/settings window
- [ ] App icon design
- [ ] Notarization for distribution

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Copyright © 2026. All rights reserved.

## Acknowledgments

Inspired by [ZoomIt](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit) by Mark Russinovich.
