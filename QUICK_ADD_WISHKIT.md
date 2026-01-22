# Quick Guide: Add WishKit Files to Xcode

## Method 1: Add Folders (Easiest - Recommended)

1. **Open Xcode**: `open Itinero.xcodeproj`

2. **In Xcode Project Navigator**:
   - Right-click on the **`Libraries`** folder (or create it if it doesn't exist)
   - Select **"Add Files to 'Itinero'..."**

3. **Select Folders**:
   - Navigate to your project directory
   - Select **`Libraries/WishKit`** folder (entire folder)
   - Hold ⌘ and also select **`Libraries/WishKitShared`** folder
   - Click **"Open"**

4. **In the Dialog**:
   - ✅ Check **"Create groups"** (NOT "Create folder references")
   - ✅ Check **"Itinero"** target checkbox
   - ❌ Uncheck **"Copy items if needed"** (files are already in place)
   - Click **"Add"**

5. **Verify**:
   - You should see `WishKit` and `WishKitShared` folders under `Libraries`
   - Select any file (e.g., `WishKit.swift`)
   - In File Inspector (right panel), check "Target Membership" → "Itinero" should be checked

6. **Clean & Build**:
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Build (⌘B)

## Method 2: Add Files Individually

If adding folders doesn't work:

1. Right-click `Libraries` → "Add Files to 'Itinero'..."
2. Navigate to `Libraries/WishKit`
3. Select ALL `.swift` files (⌘A to select all)
4. Check "Create groups" and "Itinero" target
5. Click "Add"
6. Repeat for `Libraries/WishKitShared`

## Files to Add

**WishKit**: 52 Swift files
**WishKitShared**: 12 Swift files

See `wishkit_files_to_add.txt` for the complete list.

## After Adding Files

Once files are added, update `FeatureRequestsView.swift`:

Change line 15 from:
```swift
PlaceholderFeatureRequestsView()
```

To:
```swift
WishKit.FeedbackListView()
```

Then rebuild - the wishlist feature will work!
