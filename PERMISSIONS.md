# Permission Re-Request Issue

## Why Permissions Are Re-Requested

**Root Cause**: Ad-hoc code signing creates a new signature on every build.

When you build the app without an Apple Developer certificate:
1. macOS generates an ad-hoc signature for each build
2. Each new build gets a **different** code signature
3. macOS treats each build as a **completely different app**
4. Therefore, permissions granted to the previous build don't apply to the new build

## Evidence

Try this:
```bash
# Build twice and compare signatures
xcodebuild -project LiveZoom.xcodeproj -scheme LiveZoom -configuration Debug build
codesign -dv ~/Library/Developer/Xcode/DerivedData/LiveZoom-*/Build/Products/Debug/LiveZoom.app 2>&1 | grep "Signature"

# Build again
xcodebuild clean build -project LiveZoom.xcodeproj -scheme LiveZoom -configuration Debug
codesign -dv ~/Library/Developer/Xcode/DerivedData/LiveZoom-*/Build/Products/Debug/LiveZoom.app 2>&1 | grep "Signature"

# The signatures will be different!
```

## Solutions

### Option 1: Install to Consistent Location (Current Workaround)
The `launch.sh` script copies to `~/Applications/LiveZoom.app` to minimize this issue, but even then, each rebuild changes the signature.

### Option 2: Sign with Developer ID (Recommended for Production)
```bash
# Requires Apple Developer account ($99/year)
codesign --force --deep --sign "Developer ID Application: Your Name" LiveZoom.app
```

Benefits:
- Same signature across builds
- Permissions persist
- Users don't see "unidentified developer" warnings
- Can distribute via GitHub Releases

### Option 3: Development Workflow (Current Setup)
Accept that permissions need re-granting after each rebuild:

1. **Accessibility Permission**:
   - Only needs granting once per build
   - System Settings → Privacy & Security → Accessibility
   
2. **Screen Recording Permission**:
   - Granted on first zoom attempt
   - System Settings → Privacy & Security → Screen Recording

## Testing Without Rebuilding

To test changes without re-granting permissions:
1. Make code changes
2. Build once
3. Grant permissions
4. **Don't rebuild** - just test the existing build
5. For quick iterations, modify only UI/non-critical code

## Production Release

For GitHub releases via Actions workflow:
- Use repository secrets to store signing certificate
- Sign all builds with same Developer ID
- Users grant permissions once and they persist

## Current Status

The app code correctly checks permissions before prompting:
```swift
let accessEnabled = AXIsProcessTrusted()
if !accessEnabled {
    // Only prompt if not already granted
}
```

The re-prompting is **not a bug in the code** - it's a consequence of ad-hoc signing changing the app identity with each build.
