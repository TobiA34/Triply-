# Fix "No Scheme" Issue - Manual Steps

## The Problem
Xcode is showing "No Scheme" even though the scheme file exists. This is a common Xcode caching issue.

## Solution 1: Add Scheme Through Xcode UI (RECOMMENDED)

1. **Open Xcode** with the project:
   ```bash
   open Triply.xcodeproj
   ```

2. **Go to Manage Schemes**:
   - Menu: `Product → Scheme → Manage Schemes...`
   - OR: Click the scheme dropdown → "Manage Schemes..."

3. **Add New Scheme**:
   - Click the **"+"** button (bottom left of the dialog)
   - In the popup:
     - **Name**: `Triply`
     - **Target**: Select `Triply` from the dropdown
     - **☑ Check "Shared"** (IMPORTANT!)
   - Click **"OK"**

4. **Close the dialog** and select "Triply" from the scheme dropdown

## Solution 2: Use Existing Itinero Scheme (QUICK WORKAROUND)

Since "Itinero" scheme already works, you can temporarily use it:

1. Click the scheme dropdown
2. Select **"Itinero"** (it points to the same Triply target)
3. Build and run - it will work!

## Solution 3: Clean Everything and Reopen

```bash
# Close Xcode completely first!

# Clean DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean project build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/Triply-*

# Reopen Xcode
open Triply.xcodeproj
```

Then follow Solution 1 to add the scheme.

## Verification

After adding the scheme, verify:
- Scheme dropdown shows "Triply"
- You can select a simulator/device
- Build (Cmd+B) works
- Run (Cmd+R) works

