# LiveZoom - Troubleshooting Guide

## Issue: Zoom shows only desktop background

**Cause**: Screen Recording permission not granted

**Solution**:
1. Open **System Settings** (⚙️)
2. Go to **Privacy & Security**
3. Click **Screen Recording** in the sidebar
4. Find **LiveZoom** in the list and enable it
5. **Restart LiveZoom**

💡 **Why?** macOS requires explicit permission to capture screen content. Without it, apps can only see the desktop wallpaper, not your actual windows and applications.

---

## Issue: Zoom window moves around the screen

**Status**: ✅ Fixed in latest version

If you're still seeing this:
1. Make sure you have the latest build
2. Run `./launch.sh` to rebuild and launch
3. The zoom window should now stay fixed and full-screen

---

## Issue: Hotkeys (⌘1, ⌘2) don't work

**Cause**: Accessibility permission not granted

**Solution**:
1. Open **System Settings**
2. Go to **Privacy & Security**
3. Click **Accessibility** in the sidebar
4. Find **LiveZoom** and enable it
5. Restart LiveZoom

---

## Issue: Desktop edges visible when moving cursor

**Status**: ✅ Fixed in latest version

The zoom window is now properly anchored to screen position (0,0) and won't move.

---

## Issue: Permission prompts appear every launch

**Status**: ✅ Fixed in latest version

The app now only checks Accessibility permission on launch. Screen Recording permission is checked automatically by macOS when first needed (no annoying prompts).

---

## Issue: Mirror-in-mirror effect with crosshairs

**Status**: ✅ Fixed in latest version

**Cause**: Zoom window was capturing itself

**Solution**: Now uses `CGWindowListCreateImage` with `.optionOnScreenBelowWindow` to exclude the zoom window from capture. The zoom window is completely excluded from what you see.

---

## Verifying Permissions

Run the app and check the console output (in Xcode):
- ✅ "Screen capture working - Screen Recording permission appears to be granted"
- ⚠️ "Screen capture failed - Screen Recording permission may not be granted"

---

## Quick Permission Checklist

Both of these must be enabled:

- [ ] **Accessibility** - for global hotkeys
- [ ] **Screen Recording** - for capturing screen content

Location: System Settings → Privacy & Security

---

## Still Having Issues?

1. Completely quit LiveZoom (from menu bar or Activity Monitor)
2. Re-grant both permissions in System Settings
3. Rebuild: `cd /path/to/LiveZoom && xcodebuild clean build`
4. Launch fresh: `./launch.sh`

---

## Testing Screen Capture

To test if screen recording permission is working:

1. Launch LiveZoom
2. Open any app (browser, text editor, etc.)
3. Press ⌘1 to activate zoom
4. You should see the app zoomed, not just desktop background
5. If you only see desktop, grant Screen Recording permission

---

## macOS Version Notes

- **macOS 13.0+**: Required for LiveZoom
- **Screen Recording**: Introduced in macOS 10.15 (Catalina)
- **Accessibility**: Required on all versions

---

## Debug Mode

To see detailed logging:
1. Open LiveZoom.xcodeproj in Xcode
2. Press ⌘R to run
3. Check the console for permission status messages
