# How to Add WishKit Files to Xcode Target

## Quick Fix (5 minutes)

The `WishKit` files need to be added to your Xcode target. Follow these steps:

### Step 1: Open Xcode
```bash
open Itinero.xcodeproj
```

### Step 2: Add WishKit Files
1. In Xcode, right-click on the **`Libraries`** folder in the Project Navigator
2. Select **"Add Files to 'Itinero'..."**
3. Navigate to and select:
   - `Libraries/WishKit` (select the entire folder)
   - `Libraries/WishKitShared` (select the entire folder)
4. In the dialog that appears:
   - ✅ Check **"Create groups"** (NOT "Create folder references")
   - ✅ Check the **"Itinero"** target checkbox
   - ❌ Uncheck "Copy items if needed" (files are already in the right place)
5. Click **"Add"**

### Step 3: Verify Files Are Added
1. Select any file in `Libraries/WishKit` (e.g., `WishKit.swift`)
2. Open the File Inspector (right panel, ⌥⌘1)
3. Under "Target Membership", verify **"Itinero"** is checked

### Step 4: Clean and Rebuild
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Build (⌘B)

### Step 5: Verify It Works
The `FeatureRequestsView` should now compile without errors!

## Alternative: Add Files Individually

If adding folders doesn't work:

1. Right-click `Libraries` folder → "Add Files to 'Itinero'..."
2. Navigate to `Libraries/WishKit`
3. Select ALL `.swift` files (⌘A)
4. Make sure "Create groups" and "Itinero" target are checked
5. Click "Add"
6. Repeat for `Libraries/WishKitShared`

## Troubleshooting

### "Cannot find 'WishKit' in scope"
- Files are not in the target
- Follow steps above to add them

### Files added but still not working
- Clean Build Folder (⇧⌘K)
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Itinero-*`
- Rebuild

### Still having issues?
Check that `WishKit.swift` is in the target:
1. Select `Libraries/WishKit/WishKit.swift`
2. File Inspector → Target Membership → "Itinero" should be checked
