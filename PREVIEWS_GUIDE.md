# SwiftUI Previews in Cursor/Xcode

## Overview

**Important**: SwiftUI Previews are an Xcode-only feature. Cursor (like VS Code) cannot run SwiftUI previews directly. However, you can easily work in Cursor and preview in Xcode.

## Quick Start: View Previews in Xcode

### Method 1: Quick Open Script (Recommended)

```bash
# Make script executable (first time only)
chmod +x open_in_xcode.sh

# Open project in Xcode
./open_in_xcode.sh
```

This script will:
1. Check if Xcode project exists
2. Generate it if needed (if xcodegen is installed)
3. Open Xcode automatically

### Method 2: Manual Open

1. **Create Xcode Project** (if not done):
   - Follow instructions in `SETUP.md`
   - Or run `./create_project.sh` if xcodegen is installed

2. **Open in Xcode**:
   ```bash
   open Triply.xcodeproj
   ```

3. **Enable Previews**:
   - Select any SwiftUI view file (e.g., `TripListView.swift`)
   - Press `⌥⌘↩` (Option + Command + Return) to show canvas
   - Or click the canvas toggle button in the editor toolbar

## Using Previews

### Enable Preview Canvas

1. Open any `.swift` file in the `Views/` folder
2. Look for the preview code at the bottom (starts with `#Preview`)
3. Press `⌥⌘↩` or click the canvas icon
4. Wait for preview to compile and render

### Preview Shortcuts

- **Show/Hide Canvas**: `⌥⌘↩` (Option + Command + Return)
- **Refresh Preview**: `⌘R` (while canvas is focused)
- **Pin Preview**: Click the pin icon to keep preview visible
- **Live Preview**: Click the play button to interact with preview

### Files with Previews

All view files include `#Preview` blocks:

- ✅ `ContentView.swift`
- ✅ `TripListView.swift`
- ✅ `TripDetailView.swift`
- ✅ `AddTripView.swift`
- ✅ `EditTripView.swift`
- ✅ `AddDestinationView.swift`

## Recommended Workflow

### Option A: Dual Editor Setup (Best for Development)

1. **Edit in Cursor**:
   - Use Cursor for writing/editing code
   - Take advantage of AI features
   - Use Cursor's git integration

2. **Preview in Xcode**:
   - Keep Xcode open in background
   - Switch to Xcode when you want to see previews
   - Xcode auto-reloads when files change (if project is open)

3. **Run/Build in Xcode**:
   - Use Xcode for building and running on simulator
   - Use Xcode for debugging

### Option B: Xcode Only

- Work entirely in Xcode
- Use Xcode's built-in editor
- Previews work seamlessly

## Troubleshooting Previews

### Preview Not Showing

1. **Check Canvas is Enabled**:
   - Editor → Canvas (or `⌥⌘↩`)
   - Make sure "Automatically Refresh Canvas" is enabled

2. **Check Preview Code**:
   - Each view should have a `#Preview` block at the bottom
   - Preview should provide sample data

3. **Build Errors**:
   - Check Xcode's Issue Navigator (⌘5)
   - Fix any compilation errors
   - Preview won't work if code doesn't compile

4. **Missing Environment Objects**:
   - Previews need `TripManager()` provided
   - Check that `.environmentObject(TripManager())` is in preview

### Preview Shows "Build Failed"

- Check for syntax errors
- Make sure all imports are correct
- Verify all dependencies are available
- Try cleaning build folder: Product → Clean Build Folder (⇧⌘K)

### Preview is Slow

- Close other apps
- Reduce preview complexity
- Use simpler sample data in previews
- Disable "Automatically Refresh Canvas" if needed

## Example: Viewing a Preview

1. Open `Views/TripListView.swift` in Xcode
2. Scroll to bottom - you'll see:
   ```swift
   #Preview {
       NavigationStack {
           TripListView()
               .environmentObject(TripManager())
       }
   }
   ```
3. Press `⌥⌘↩` to show canvas
4. Preview will render on the right side
5. You can interact with it (tap buttons, navigate, etc.)

## Running the Full App

To run the complete app (not just preview):

1. **In Xcode**:
   - Select a simulator or device
   - Press `⌘R` or click Play button
   - App launches in simulator

2. **From Terminal** (if project exists):
   ```bash
   xcodebuild -project Triply.xcodeproj \
              -scheme Triply \
              -destination 'platform=iOS Simulator,name=iPhone 15' \
              build
   ```

## Tips

- **Keep Xcode Open**: If you edit files in Cursor, Xcode can auto-detect changes
- **Use Previews for Quick Iteration**: Faster than building full app
- **Pin Multiple Previews**: View different states simultaneously
- **Preview on Different Devices**: Use device selector in preview

## Limitations

- ❌ Previews only work in Xcode
- ❌ Cursor cannot show SwiftUI previews
- ✅ But you can edit in Cursor and preview in Xcode seamlessly

---

**Quick Command Reference**:
```bash
# Open in Xcode
./open_in_xcode.sh

# Or manually
open Triply.xcodeproj

# In Xcode: Show preview canvas
⌥⌘↩ (Option + Command + Return)
```



