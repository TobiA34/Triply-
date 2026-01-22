# Triply - Trip Planning App

A beautiful SwiftUI app for planning and managing your trips.

## Features

- ✈️ Create and manage multiple trips
- 📍 Add destinations to your trips
- 📅 Set trip dates and duration
- 📝 Add notes for trips and destinations
- 🗑️ Delete trips and destinations
- ✏️ Edit trip details

## Project Structure

```
Triply/
├── TriplyApp.swift          # App entry point
├── Models/
│   ├── Trip.swift           # Trip data model
│   └── Destination.swift    # Destination data model
├── Managers/
│   └── TripManager.swift    # State management for trips
├── Views/
│   ├── ContentView.swift    # Root view
│   ├── TripListView.swift   # List of all trips
│   ├── TripDetailView.swift # Trip details and destinations
│   ├── AddTripView.swift    # Create new trip
│   ├── EditTripView.swift   # Edit existing trip
│   └── AddDestinationView.swift # Add destination to trip
└── Info.plist              # App configuration
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### Quick Setup

1. **Open Xcode** and create a new iOS App project
2. **Configure**: SwiftUI, iOS 17.0+, Bundle ID: `com.triply.app`
3. **Delete** the default `TriplyApp.swift` and `ContentView.swift` files
4. **Add existing files** from this directory to your Xcode project:
   - All `.swift` files
   - `Models/`, `Managers/`, `Views/` folders
   - `Info.plist`
5. **Set Info.plist** path in Build Settings
6. **Build and run** (⌘R)

📖 **Detailed setup instructions**: See [SETUP.md](SETUP.md)

## 🚀 Running in Cursor (Terminal)

**Run directly from Cursor terminal**:
```bash
./run.sh          # Build and run in simulator
./build.sh        # Just build
./watch.sh        # Auto-rebuild on file changes
```

📖 **Cursor Workflow**: See [CURSOR_WORKFLOW.md](CURSOR_WORKFLOW.md) for complete guide

## SwiftUI Previews

**Quick Preview Setup** (requires Xcode):
```bash
./open_in_xcode.sh  # Opens Xcode project
# Then in Xcode: Press ⌥⌘↩ to show preview canvas
```

📱 **Preview Guide**: See [PREVIEWS_GUIDE.md](PREVIEWS_GUIDE.md) for detailed instructions  
⚡ **Quick Start**: See [QUICK_START.md](QUICK_START.md) for fastest setup

## MVP Features

This MVP includes:
- Basic trip creation and management
- Destination management within trips
- Date range selection
- Notes for trips and destinations
- Clean, modern SwiftUI interface
- Sample data for demonstration

## Future Enhancements

Potential features for future versions:
- Persistent storage (Core Data or SwiftData)
- Trip sharing
- Maps integration
- Photo attachments
- Budget tracking
- Itinerary timeline view

