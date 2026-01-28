# Itinero

A beautiful, feature-rich iOS app for planning and managing your trips. Built with SwiftUI and SwiftData.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## ✨ Features

### Trip Management
- ✈️ Create and manage multiple trips with detailed information
- 📍 Add multiple destinations to trips with location search
- 📅 Set trip dates, duration, and travel companions
- 💰 Budget tracking with category breakdowns
- 🏷️ Organize trips with categories and tags
- 📝 Rich notes and trip memories

### Planning Tools
- 🗺️ Interactive maps with nearby places discovery
- 📋 Itinerary timeline with activities and events
- 🎒 Packing list management
- 💳 Expense tracking by category
- 📊 Analytics and statistics dashboard
- 🎯 Smart trip templates for quick planning

### User Experience
- 🎨 Customizable themes (Light, Dark, System)
- 🌍 Multi-language support
- 💱 Multi-currency support with dynamic formatting
- 📱 iOS Widgets for quick trip access
- 🔔 Trip reminders and notifications
- 📸 Document management for travel papers

### Advanced Features
- 🤖 AI-powered budget insights
- 🔍 Smart destination search
- 📈 Spending analytics and predictions
- 🎨 Custom theme creation
- 🔄 Trip collaboration features
- 📱 Live Activities support

## 🏗️ Architecture

Built with modern iOS development practices:

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern data persistence
- **MVVM** - Clean architecture pattern
- **Combine** - Reactive programming
- **WidgetKit** - Home screen widgets
- **Core Location** - Location services
- **UserNotifications** - Reminders and alerts

## 📋 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ (for development)

## 🚀 Getting Started

### Prerequisites

1. Install [Xcode](https://developer.apple.com/xcode/) 15.0 or later
2. Ensure you have a valid Apple Developer account (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Triply
   ```

2. **Open the workspace**
   ```bash
   open Itinero.xcworkspace
   ```
   > Note: Use the `.xcworkspace` file, not `.xcodeproj`

3. **Install dependencies**
   - CocoaPods dependencies will be installed automatically
   - If needed, run: `pod install`

4. **Configure the project**
   - Update the Bundle Identifier in Xcode if needed
   - Configure signing & capabilities for your team

5. **Build and run**
   - Select a simulator or connected device
   - Press `⌘R` to build and run

### Quick Run Scripts

```bash
./run.sh          # Build and run in simulator
./run_device.sh   # Build and run on connected device
./build.sh        # Just build the project
./watch.sh        # Auto-rebuild on file changes
```

## 📁 Project Structure

```
Itinero/
├── ItineroApp.swift          # App entry point
├── Models/                    # SwiftData models
│   ├── TripModel.swift
│   ├── DestinationModel.swift
│   ├── ItineraryItem.swift
│   ├── Expense.swift
│   └── ...
├── Views/                     # SwiftUI views
│   ├── ContentView.swift      # Root view
│   ├── TripListView.swift     # Main trip list
│   ├── TripDetailView.swift   # Trip details
│   ├── AddTripView.swift      # Trip creation
│   ├── AnalyticsView.swift    # Statistics & analytics
│   └── ...
├── Managers/                   # Business logic
│   ├── SettingsManager.swift  # App settings
│   ├── TripDataManager.swift  # Data operations
│   ├── FreePlacesManager.swift # Places discovery
│   └── ...
├── Widgets/                    # iOS Widgets
│   └── TripStatsWidget.swift
├── Extensions/                 # Swift extensions
├── Components/                 # Reusable UI components
├── Resources/                  # Assets & localizations
└── ItineroUITests/            # UI test suite
```

## 🧪 Testing

The project includes comprehensive UI tests:

```bash
# Run all tests
xcodebuild test -workspace Itinero.xcworkspace -scheme Itinero

# Run specific test suite
xcodebuild test -workspace Itinero.xcworkspace -scheme Itinero \
  -only-testing:ItineroUITests/ScreenshotUITests
```

### Test Coverage

- ✅ Trip management (create, edit, delete)
- ✅ Form validation
- ✅ Permissions handling
- ✅ Orientation support
- ✅ Screenshot capture
- ✅ Expense tracking
- ✅ Itinerary management

## 🎨 Customization

### Themes

The app supports multiple themes:
- Light Mode
- Dark Mode
- System (follows device setting)
- Custom themes (user-created)

### Localization

Currently supports:
- English
- Additional languages can be added via `Resources/Localizable.strings`

### Currency

Supports all major currencies with dynamic formatting:
- USD, EUR, GBP, JPY, CAD, AUD, and more
- Automatic symbol and formatting based on selection

## 📱 Widgets

The app includes iOS widgets for quick access:
- Trip Statistics Widget
- Upcoming Trips Widget
- Active Trip Widget

Add widgets from the home screen by long-pressing and selecting "Itinero".

## 🔐 Permissions

The app requests the following permissions:
- **Location** - For maps and nearby places
- **Camera** - For document scanning
- **Photo Library** - For trip photos
- **Notifications** - For trip reminders
- **Calendar** - For itinerary events

All permissions are optional and the app gracefully handles denied permissions.

## 🛠️ Development

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain MVVM architecture
- Write self-documenting code

### Contributing

1. Create a feature branch
2. Make your changes
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Uses [SwiftData](https://developer.apple.com/documentation/swiftdata) for persistence
- Icons and UI elements use SF Symbols

## 📞 Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Contact: tobiadegoroye49@gmail.com

---

Made with ❤️ using SwiftUI
