# LiveZoom - Quick Start Guide

## What is LiveZoom?

LiveZoom is a macOS presentation and annotation tool that allows you to:
- **Zoom** into any part of your screen for better visibility during demos
- **Draw** annotations directly on your screen while presenting
- Control everything via convenient keyboard shortcuts

## How to Run

### Option 1: Quick Launch
```bash
./launch.sh
```

### Option 2: Open in Xcode
```bash
open LiveZoom.xcodeproj
```
Then press ⌘R to build and run.

### Option 3: Direct Launch
After building, the app will be in your menu bar (look for the viewfinder icon 🎯).

## First Time Setup

When you launch LiveZoom for the first time:

1. You'll see a prompt asking for **Accessibility** permissions
2. Click "Open System Settings"
3. Toggle the switch next to LiveZoom to enable it
4. You may also be prompted for **Screen Recording** permission
5. Enable LiveZoom in Screen Recording as well
6. Restart LiveZoom

These permissions are required for:
- **Accessibility**: Global keyboard shortcuts and event monitoring
- **Screen Recording**: Capturing and magnifying screen content

## How to Use

### Zoom Mode (⌘1)

1. Press **⌘1** anywhere on your Mac
2. A zoomed view appears centered on your mouse position
3. **Scroll** or use **↑/↓ arrow keys** to zoom in/out
4. Use **arrow keys** to pan the view
5. Press **Escape** or **right-click** to exit

**Use Cases:**
- Highlighting small UI elements during demos
- Reading tiny text
- Showing code details
- Focusing audience attention on specific areas

### Drawing Mode (⌘2)

1. Press **⌘2** anywhere on your Mac
2. A transparent overlay appears over your entire screen
3. **Click and drag** to draw with the mouse
4. Press **R**, **G**, **B**, or **Y** to change pen colors
5. Press **Delete** to undo the last drawing
6. Press **E** to erase everything
7. Press **Escape** or **right-click** to exit

**Use Cases:**
- Highlighting important points during presentations
- Circling areas of interest
- Drawing arrows to direct attention
- Making quick notes during screen shares

### Menu Bar Options

Click the viewfinder icon (🎯) in your menu bar to:
- Access all features via menu
- View keyboard shortcuts
- Quit the application

## Keyboard Shortcuts Reference

| Shortcut | Action |
|----------|--------|
| ⌘1 | Zoom Mode |
| ⌘2 | Drawing Mode |
| ⌘Q | Quit (when menu is focused) |

**In Zoom Mode:**
- Mouse movement = Pan around snapshot
- Scroll / ↑↓ = Zoom in/out
- Arrow keys = Pan manually
- Esc / Right-click = Exit
- Note: Shows a snapshot (frozen), not live video

**In Drawing Mode:**
- R = Red pen
- G = Green pen
- B = Blue pen
- Y = Yellow pen
- Delete = Undo last
- E = Erase all
- Esc / Right-click = Exit

## Tips & Tricks

1. **Quick Color Switching**: While drawing, you can change colors mid-stroke by pressing R, G, B, or Y

2. **Practice First**: Try the features on your desktop before using in a presentation

3. **Zoom During Drawing**: You can use Zoom mode first to find the right spot, exit, then enter Drawing mode to annotate

4. **System-Wide**: LiveZoom works in any application - during video calls, screen sharing, presentations, anything!

5. **Multiple Monitors**: LiveZoom will appear on your primary display

## Troubleshooting

### Hotkeys Not Working?
- Verify Accessibility permissions are enabled
- Go to System Settings → Privacy & Security → Accessibility
- Make sure LiveZoom is checked

### Zoom Shows Black or Frozen Screen?
- Grant Screen Recording permission
- Go to System Settings → Privacy & Security → Screen Recording
- Enable LiveZoom and restart the app

## What's Next?

Current features are just the beginning! Planned enhancements include:

- **Advanced Drawing Tools**: Lines, rectangles, circles, arrows
- **Text Annotations**: Type text directly on screen
- **Screenshots**: Capture and save what you're showing
- **Screen Recording**: Record your presentations
- **Timer**: Countdown timer for time management
- **LiveZoom**: Real-time magnification that follows your cursor

## Feedback

This is version 1.0 with core features. More to come!

Enjoy using LiveZoom! 🎯
