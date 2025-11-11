# Manual Xcode Project Setup

If you prefer to create the Xcode project manually or if xcodegen is not available, follow these steps:

## Option 1: Create Project in Xcode (Recommended)

1. Open Xcode
2. Select "File" → "New" → "Project"
3. Choose "iOS" → "App"
4. Fill in the details:
   - Product Name: `Triply`
   - Team: (Select your team)
   - Organization Identifier: `com.triply`
   - Bundle Identifier: `com.triply.app`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None` (we'll use in-memory for MVP)
   - Minimum iOS Version: `17.0`
5. Choose the location (select the parent directory, not the Triply folder)
6. Click "Create"

7. **Important**: Delete the default `ContentView.swift` and `TriplyApp.swift` that Xcode creates, as we already have our own versions.

8. **Add existing files to the project**:
   - Right-click on the project in the navigator
   - Select "Add Files to Triply..."
   - Select all the files and folders:
     - `TriplyApp.swift`
     - `Models/` folder
     - `Managers/` folder
     - `Views/` folder
     - `Info.plist`
   - Make sure "Copy items if needed" is **unchecked**
   - Make sure "Create groups" is selected
   - Click "Add"

9. **Update Build Settings**:
   - Select the project in the navigator
   - Select the "Triply" target
   - Go to "Build Settings"
   - Search for "Info.plist File"
   - Set it to `Info.plist`

10. **Update Info.plist**:
    - Make sure the Info.plist file is properly configured (already done)

11. Build and run (⌘R)

## Option 2: Use xcodegen (Automated)

1. Install xcodegen:
   ```bash
   brew install xcodegen
   ```

2. Run the setup script:
   ```bash
   chmod +x create_project.sh
   ./create_project.sh
   ```

3. Open the generated project:
   ```bash
   open Triply.xcodeproj
   ```

## Project Structure

After setup, your Xcode project should have this structure:

```
Triply/
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

## Troubleshooting

- **Build errors**: Make sure all files are added to the target
- **Missing files**: Check that files are in the correct groups in Xcode
- **Info.plist errors**: Verify the Info.plist file path in Build Settings



