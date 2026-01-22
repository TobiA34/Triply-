# How to See WishKit Files in Xcode

## Problem: Files exist but aren't visible in Xcode

The files are in your file system at:
- `Libraries/WishKit/` (52 Swift files)
- `Libraries/WishKitShared/` (12 Swift files)

But they won't appear in Xcode until you add them to the project.

## Solution: Add Files to Xcode Project

### Step-by-Step with Screenshots Guide:

#### Step 1: Open Xcode Project
```bash
open Itinero.xcodeproj
```

#### Step 2: Find the Libraries Folder
- In the **Project Navigator** (left sidebar), look for a folder called **"Libraries"**
- If you don't see it, it might be collapsed - click the arrow to expand
- If it doesn't exist at all, you'll create it in the next step

#### Step 3: Add the WishKit Folders

**Option A: If Libraries folder exists in Xcode:**
1. Right-click on **"Libraries"** folder in Project Navigator
2. Select **"Add Files to 'Itinero'..."**
3. In the file picker dialog:
   - Navigate to your project folder: `/Users/tobiadegoroye/Developer/SwiftUI/Triply`
   - Open the **"Libraries"** folder
   - You should see **"WishKit"** and **"WishKitShared"** folders
   - Select BOTH folders (hold ⌘ to select multiple)
   - Click **"Open"**

**Option B: If Libraries folder doesn't exist:**
1. Right-click on the **"Itinero"** project (top item in Project Navigator)
2. Select **"Add Files to 'Itinero'..."**
3. Navigate to `Libraries` folder
4. Select **"WishKit"** and **"WishKitShared"** folders
5. Click **"Open"**

#### Step 4: Configure the Add Dialog
When the dialog appears, make sure:
- ✅ **"Create groups"** is checked (NOT "Create folder references")
- ✅ **"Itinero"** target is checked (under "Add to targets")
- ❌ **"Copy items if needed"** is UNCHECKED (files are already in place)
- Click **"Add"**

#### Step 5: Verify Files Appeared
After clicking "Add", you should see:
- In Project Navigator: `Libraries` → `WishKit` → (all the Swift files)
- In Project Navigator: `Libraries` → `WishKitShared` → (all the Swift files)

#### Step 6: Verify Target Membership
1. Click on any file (e.g., `WishKit.swift`)
2. Open the **File Inspector** (right panel, or ⌥⌘1)
3. Under **"Target Membership"**, verify **"Itinero"** is checked ✅

#### Step 7: Clean and Build
- Product → Clean Build Folder (⇧⌘K)
- Product → Build (⌘B)

## Troubleshooting

### "I can't see the Libraries folder in Xcode"
- The folder might be collapsed - look for a small arrow ▶ next to folders
- Click the arrow to expand
- Or add the files directly to the project root

### "I can't find the WishKit folder when browsing"
- Make sure you're browsing from the project root: `/Users/tobiadegoroye/Developer/SwiftUI/Triply`
- The folders are at: `Libraries/WishKit` and `Libraries/WishKitShared`
- Try using "Go to Folder" (⇧⌘G) and type: `Libraries`

### "Files added but still can't see them"
- Check if they're in a different group/folder
- Use the search bar at the bottom of Project Navigator to search for "WishKit"
- Make sure "Show only files with source control status" isn't filtering them out

### "Files show but have a red icon"
- Red icon means Xcode can't find the file at that path
- Right-click the file → "Show in Finder" to verify location
- If path is wrong, remove and re-add the files

## Quick Verification Commands

Run these in Terminal to verify files exist:
```bash
cd /Users/tobiadegoroye/Developer/SwiftUI/Triply
ls Libraries/WishKit/*.swift | wc -l    # Should show 52
ls Libraries/WishKitShared/*.swift | wc -l  # Should show 12
```

## After Adding Files

Once files are visible in Xcode and added to the target:
1. Update `FeatureRequestsView.swift` line 15:
   - Change: `PlaceholderFeatureRequestsView()`
   - To: `WishKit.FeedbackListView()`
2. Build should succeed! ✅
