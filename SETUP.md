# Triply - Setup Instructions

## Quick Start

### Option 1: Create Project in Xcode (Easiest)

1. **Open Xcode** (version 15.0 or later)

2. **Create New Project**:
   - File → New → Project
   - Select "iOS" → "App"
   - Click "Next"

3. **Configure Project**:
   - Product Name: `Triply`
   - Team: Select your development team
   - Organization Identifier: `com.triply`
   - Bundle Identifier: `com.triply.app` (auto-generated)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we use in-memory storage for MVP)
   - Minimum iOS Version: **17.0**
   - Click "Next"

4. **Choose Location**:
   - Navigate to the **parent directory** of your Triply folder
   - **Important**: Do NOT select the Triply folder itself
   - Click "Create"

5. **Replace Default Files**:
   - Delete the auto-generated `TriplyApp.swift` and `ContentView.swift` files
   - Right-click in the project navigator → Delete → Move to Trash

6. **Add Existing Files**:
   - Right-click on the project name in navigator
   - Select "Add Files to 'Triply'..."
   - Navigate to your Triply source folder
   - Select ALL files and folders:
     - `TriplyApp.swift`
     - `Models/` folder (select the folder)
     - `Managers/` folder (select the folder)
     - `Views/` folder (select the folder)
     - `Info.plist`
   - **Important Settings**:
     - ✅ Uncheck "Copy items if needed" (files are already in place)
     - ✅ Select "Create groups" (not folder references)
     - ✅ Make sure "Triply" target is checked
   - Click "Add"

7. **Configure Build Settings**:
   - Select the project in navigator (blue icon at top)
   - Select the "Triply" target
   - Go to "Build Settings" tab
   - Search for "Info.plist File"
   - Set value to: `Info.plist`

8. **Build and Run**:
   - Select a simulator or device
   - Press ⌘R or click the Play button
   - The app should launch!

### Option 2: Use xcodegen (Automated)

If you have `xcodegen` installed:

```bash
# Install xcodegen (if not installed)
brew install xcodegen

# Generate Xcode project
cd /Users/tobiadegoroye/Developer/SwiftUI/Triply
./create_project.sh

# Open the project
open Triply.xcodeproj
```

### Option 3: Swift Package (Alternative)

If you prefer Swift Package Manager, you can create a Package.swift, but note that this is primarily for libraries. For iOS apps, Xcode project is recommended.

## Project Structure

After setup, your Xcode project should look like this:

```
Triply (Project)
└── Triply (Target)
    ├── TriplyApp.swift
    ├── Models/
    │   ├── Trip.swift
    │   └── Destination.swift
    ├── Managers/
    │   └── TripManager.swift
    ├── Views/
    │   ├── ContentView.swift
    │   ├── TripListView.swift
    │   ├── TripDetailView.swift
    │   ├── AddTripView.swift
    │   ├── EditTripView.swift
    │   └── AddDestinationView.swift
    └── Info.plist
```

## Verify Setup

1. **Build the project** (⌘B)
   - Should compile without errors

2. **Run the app** (⌘R)
   - Should launch on simulator/device
   - You should see a sample trip "Summer Europe Adventure"

3. **Test Features**:
   - ✅ View trips list
   - ✅ Tap trip to see details
   - ✅ Add new trip (+ button)
   - ✅ Edit trip (Edit button)
   - ✅ Add destinations
   - ✅ Delete trips/destinations

## Troubleshooting

### "Cannot find 'TriplyApp' in scope"
- Make sure `TriplyApp.swift` is added to the target
- Check Target Membership in File Inspector

### "Info.plist not found"
- Verify Info.plist path in Build Settings
- Make sure Info.plist is in the project root

### "No such module 'SwiftUI'"
- Make sure you're targeting iOS 17.0+
- Check Deployment Target in Build Settings

### Files not showing in Xcode
- Make sure files are added to the correct target
- Check "Target Membership" in File Inspector (right panel)

### Build errors about missing files
- Verify all files are added to the "Triply" target
- Clean build folder: Product → Clean Build Folder (⇧⌘K)

## Requirements

- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.9 or later
- **macOS**: 14.0 (Sonoma) or later for development

## Next Steps

Once the app is running:
1. Explore the UI and features
2. Customize the design
3. Add persistent storage (Core Data or SwiftData)
4. Add more features from the roadmap

Enjoy planning your trips! ✈️



