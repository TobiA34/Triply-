# Quick Start - SwiftUI Previews

## 🚀 Fastest Way to See Previews

```bash
# 1. Open project in Xcode (auto-creates if needed)
./open_in_xcode.sh

# 2. In Xcode: Open any view file and press
⌥⌘↩ (Option + Command + Return)
```

## 📱 Step-by-Step

### First Time Setup

1. **Create Xcode Project** (one-time):
   ```bash
   # Option A: Use xcodegen (if installed)
   brew install xcodegen  # if needed
   ./create_project.sh
   
   # Option B: Manual (see SETUP.md)
   # Open Xcode → New Project → Follow SETUP.md
   ```

2. **Open in Xcode**:
   ```bash
   ./open_in_xcode.sh
   # Or: open Triply.xcodeproj
   ```

### View Previews

1. **In Xcode**, open any file from `Views/` folder:
   - `TripListView.swift`
   - `TripDetailView.swift`
   - `AddTripView.swift`
   - etc.

2. **Show Preview Canvas**:
   - Press `⌥⌘↩` (Option + Command + Return)
   - Or: Editor → Canvas
   - Or: Click the canvas icon in toolbar

3. **Preview will appear** on the right side showing the UI

4. **Interact with preview**:
   - Click buttons
   - Navigate between views
   - Test forms
   - See live updates as you edit code

## 🎯 Workflow: Edit in Cursor, Preview in Xcode

1. **Edit code in Cursor** (your current editor)
2. **Keep Xcode open** in background
3. **Switch to Xcode** when you want to see previews
4. **Xcode auto-reloads** when files change (if enabled)

## ⌨️ Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Show/Hide Preview | `⌥⌘↩` |
| Refresh Preview | `⌘R` (in canvas) |
| Pin Preview | Click pin icon |
| Run Full App | `⌘R` (in Xcode) |

## ✅ All Views Have Previews

Every view file includes a `#Preview` block:
- ✅ ContentView
- ✅ TripListView  
- ✅ TripDetailView
- ✅ AddTripView
- ✅ EditTripView
- ✅ AddDestinationView

## 🔧 Troubleshooting

**Preview not showing?**
- Make sure Xcode project exists: `./open_in_xcode.sh`
- Check for build errors in Xcode
- Try: Product → Clean Build Folder (⇧⌘K)

**Want more details?**
- See `PREVIEWS_GUIDE.md` for comprehensive guide

---

**TL;DR**: Run `./open_in_xcode.sh`, then press `⌥⌘↩` in Xcode! 🎉



