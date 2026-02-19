# Screen Recording Permission - Development Build Issue

## The Problem

You're seeing the Screen Recording permission dialog every time you activate zoom (⌘1), and you only see the desktop background even after granting permission.

## Root Cause: Ad-Hoc Code Signing

This happens because the app is built with **ad-hoc code signing** (no developer certificate). Here's what's happening:

1. **Every rebuild gets a new signature** - macOS uses the code signature to identify apps
2. **macOS treats each rebuild as a "different app"** - permissions don't carry over
3. **Old permissions become orphaned** - they're tied to the old signature
4. **Desktop-only capture** - without proper Screen Recording permission, `CGDisplayCreateImage()` only captures the wallpaper, not windows

## The Solution

### Option 1: Use Consistent Install Location (Recommended for Development)

The updated `launch.sh` script now:
1. Builds the app
2. Copies it to `~/Applications/LiveZoom.app` (consistent location)
3. Launches from there

This helps macOS recognize the app more consistently between rebuilds.

**Steps:**
```bash
./launch.sh
```

Then:
1. Open **System Settings** → **Privacy & Security** → **Screen Recording**
2. Look for **LiveZoom** in the list
3. If you see multiple entries or it's not working:
   - Click the **(-)** button to remove old entries
   - Click the **(+)** button to add `~/Applications/LiveZoom.app`
4. Enable the checkbox
5. Quit and relaunch LiveZoom

### Option 2: Sign with Developer Certificate (For Production)

To properly sign the app:

1. **Get an Apple Developer account** ($99/year)
2. **Create a Developer ID Application certificate**
3. **Update the Xcode project:**
   - Open project settings
   - Select the LiveZoom target
   - Go to "Signing & Capabilities"
   - Select your Team
   - Choose "Developer ID Application" as signing certificate

Once signed with a real certificate:
- ✅ Permission persists across rebuilds
- ✅ macOS recognizes it as the same app
- ✅ One-time permission grant
- ✅ Ready for distribution

### Option 3: Accept the Limitation (Quick Testing)

For quick testing during development:

1. Build and run from Xcode (⌘R)
2. When zoom activates, grant Screen Recording permission
3. Test your changes
4. Next rebuild = repeat permission grant

This is tedious but works for rapid iteration.

## Why Desktop Background Only?

When Screen Recording permission is **denied or not granted**, `CGDisplayCreateImage()`:
- ✅ **Succeeds** (doesn't fail)
- ✅ **Returns a valid image**
- ❌ **BUT only captures the desktop wallpaper**, not windows

This is a macOS security feature. The API doesn't fail; it just returns limited content.

## Checking Permission Status

Unfortunately, there's **no reliable API** to check if Screen Recording permission is granted. The only way to know is:
1. Try to capture
2. Check if you got real content or just desktop
3. But distinguishing desktop-only from "user actually has nothing open" is hard

## Verifying It Works

After granting permission correctly:

1. **Open some apps** (browser, text editor, etc.)
2. **Press ⌘1**
3. **You should see:** Apps, windows, content - NOT just desktop wallpaper
4. **Move mouse** to pan around
5. **Scroll** to zoom

If you only see desktop wallpaper → permission not properly granted to THIS build.

## Development Workflow

**Recommended flow:**

```bash
# 1. Make code changes

# 2. Build and install to consistent location
./launch.sh

# 3. First time or after rebuild:
#    - Open System Settings → Screen Recording
#    - Remove old LiveZoom entries
#    - Add ~/Applications/LiveZoom.app
#    - Grant permission

# 4. Test your changes

# 5. Repeat
```

## Future: Production Distribution

Before distributing LiveZoom to others:

1. Sign with Developer ID certificate
2. Notarize the app with Apple
3. Create a DMG or PKG installer
4. Users install once, grant permission once, done

The permission issue you're experiencing is a **development-time limitation**, not a bug in LiveZoom itself.

## Quick Reference

| Symptom | Cause | Fix |
|---------|-------|-----|
| Dialog every time | Ad-hoc signing | Use consistent install location or get dev certificate |
| Desktop only | Permission not granted to this build | Re-grant permission after each rebuild |
| Multiple LiveZoom entries in Settings | Multiple builds with different signatures | Remove old entries, keep only current |

---

**TL;DR**: Development builds with ad-hoc signing need permission granted after each rebuild. Use `./launch.sh` to install to a consistent location and make the process easier.
