# Bugs Fixed & Missing / Incomplete Features

## Bugs fixed (latest pass – app scan)

### Force unwraps and optional safety – fixed
- **PackingListView**: `$0.bagName!` in `itemsByBag` filter → now uses `($0.bagName ?? "").isEmpty == false`.
- **ItineraryView**: `activity.estimatedCost!` and `activity.estimatedDuration!` in edit activity init → now use `.map { ... } ?? ""`.
- **EditTripView**: `trip.budget!` in init → now uses `trip.budget.map { String(Int($0)) } ?? ""`.
- **EditDocumentView**: `document.amount!` in init → now uses `document.amount.map { String(format: "%.2f", $0) } ?? ""`.
- **TriplyWidgetExtension/EnhancedTripWidget**: `trip!` and `entry.trip!` → now use `.map` / `.flatMap` for optional trip and widget URL.
- **AppleAIFoundation**: `items!` when building create_itinerary action → now uses `if let generatedItems = items, !generatedItems.isEmpty` and `generatedItems.count`.
- **ItineroApp**: Final `try!` in `createFallbackContainer()` → replaced with `fatalError(...)` so failure is explicit instead of force-unwrap crash.

### Localization
- **appleAIFoundation.save.itemscount.itinerary.items**: Value was literal `\\(items!.count)`; now uses format string `"Save %d itinerary items"` and `String(format: ..., generatedItems.count)` at call site.

### Preview-only (no crash in previews)
- **ExpenseChartView**, **EnhancedTripCard**: `try! ModelContainer` in `#Preview` → `guard let container = try? ... else { return AnyView(Text("Preview unavailable")) }`.
- **CurrencyPickerLibrary**, **LanguagePickerLibrary**: `.first!` in preview → `.first ?? EnhancedCurrency(...)` / `EnhancedLanguage(...)` with sensible defaults.

### Feature fix (build)
- **Components/ModernFormComponents.swift**: File was empty while the project references it; **ModernButton** (and other form components) were only in Views/ModernFormComponents.swift. Restored full implementation into Components/ModernFormComponents.swift so AddDestinationView and other views that use **ModernButton** compile. Renamed inner enum to **ModernButtonStyle** to avoid clashing with SwiftUI’s `ButtonStyle`. Replaced `.contentFilterAlert(...)` with standard `.alert(...)` so the Components file does not depend on ContentFilterAlert (not in target).
- **Views/DocumentsView.swift**: **BatchTicketScanView** was missing; added a placeholder struct so the batch-scan sheet compiles. Refactored the main body into `documentsScrollContent`, `documentsActionButtons`, `documentsFoldersSection`, and `documentsListSection` to fix “compiler unable to type-check this expression in reasonable time”.
- **Views/InlineContactFormView.swift**: Broke up the form body into `formContent`, `nameField`, `emailField`, `messageField`, and `sendButton` to fix type-check timeout.

### Trips page (same treatment – refactor for type-check and structure)
- **Views/TripListView.swift**: Extracted `tripListScrollContent` (hero, search, stats, section list) and `tripListMainContent` (ZStack with background, empty state or scroll). Body now returns `NavigationStack { tripListMainContent ... }` with modifiers, so the compiler type-checks smaller subviews.
- **Views/TripDetailView.swift**: Extracted `tripDetailScrollBody` (VStack with hero, tab strip, and tab content Group). Body now returns `GeometryReader { ScrollView { tripDetailScrollBody } .background(...) .coordinateSpace(...) }` plus the same modifiers, reducing the size of the single expression the type checker sees.

---

## Bugs fixed (previous pass)

### Crash risks (force unwraps) – fixed
- **TripDetailView**: Cover image used `trip.coverImageData!` with `UIImage(data:)`; invalid data could crash. Now uses `trip.coverImageData.flatMap { UIImage(data: $0) }`.
- **TripDetailView**: "View Original Post" and "Reviews" links used `URL(string: ...)!`; malformed URLs could crash. Now only show links when `URL(string:)` succeeds.
- **EditTripView**: Budget init used `trip.budget!`. Replaced with `trip.budget.map { String(Int($0)) } ?? ""`.
- **EditDocumentView**: Amount init used `document.amount!`. Replaced with `document.amount.map { String(format: "%.2f", $0) } ?? ""`.
- **AnalyticsView**: Monthly breakdown used `monthKey.month!` and `monthKey.year!`. Replaced with `guard let month = monthKey.month, let year = monthKey.year else { continue }`.
- **ItineraryView** (edit activity): `activity.estimatedCost!` and `activity.estimatedDuration!` in init. Replaced with optional `.map` and `?? ""`.
- **EnhancedLocationManager**: Used `currentLocation!` after nil check. Replaced with `if let location = currentLocation { status = .located(location) }`.

### Left as-is (acceptable risk)
- **ItineroApp**: `try!` in last-resort `createFallbackContainer()` – intentional emergency path.
- **ExpenseChartView / EnhancedTripCard**: `try! ModelContainer` in `#Preview` only – preview-only, not shipped.
- **CurrencyPickerLibrary**: `.first!` in preview – preview-only.

---

## Missing or incomplete features

### 1. Automated itinerary generation – **implemented**
- **Location**: `Managers/TripOptimizer.swift` – `generateAutomatedItinerary(for:)` returns `[ItineraryDraft]`; `Views/ItineraryView.swift` creates `ItineraryItem` from drafts and saves.
- **Behavior**: Builds day-by-day items from trip dates and destinations (e.g. "Arrive – [dest]", "Explore [dest]", "Travel to [next]"). User taps "Auto-Generate Itinerary" when the trip has destinations and an empty itinerary.
- **Test**: `ItineraryUITests.testAutoGenerateItinerary()` taps the button and asserts generated content appears.

### 2. Export as PDF – **implemented**
- **TierPlan** says "Export itinerary as **PDF**".
- **Current**: `ExportManager.exportTripToPDFData(trip:)` uses `UIGraphicsPDFRenderer` to produce a real PDF (Data). TripExportView has "Export as PDF" that writes to a temp file and shares it.
- **Legacy**: `exportTripToPDF(trip:)` still returns plain text (used for preview and "Export as Text"). (Obsolete note removed.) the “PDF” wording in the tier plan.

### 3. UI tests and destination
- **ItineroUITests**: Running with `-destination 'platform=iOS Simulator,name=iPhone 16'` failed with exit code 70 (destination not found on this machine).
- **Suggestion**: Run UI tests from Xcode and pick an available simulator, or use a destination that exists in your Xcode (e.g. `iPhone 15`, `iPhone 16 Pro` with explicit OS).

---

## Quick checklist (what’s in good shape)

- Pro limits (trips, destinations, expenses, activities, packing, documents, folders) are enforced with paywall.
- Pro tools (AI Plan, Optimizer, Budget, Collaborate, Smart Packing, Export, Social Import, Pro templates, Expense splitting, Folder customization) are gated.
- Add to Calendar is available from Export and from trip detail overflow menu (Pro).
- RevenueCat: multiple packages, intro eligibility, manage subscriptions, `setUserEmail` – all wired (assuming SDK is linked via WishKit’s purchases-ios).
- No remaining user-facing force unwraps in the files that were edited.
