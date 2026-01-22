+ ## Triply Test Plan
+ 
+ Version: 1.0
+ Owner: QA/Dev team
+ Last updated: 2025-11-11
+ 
+ 
+ ## 1. Objectives
+ - Ensure Triply’s core user journeys work reliably across supported iOS devices and versions.
+ - Validate correctness of calculations (currency conversion, statistics, optimization) and persistence.
+ - Verify end-to-end integrations (OCR, export/sharing, notifications, weather API stubs, localization).
+ - Maintain app quality via automated checks, performance benchmarks, and accessibility conformance.
+ 
+ 
+ ## 2. Scope
+ - In scope:
+   - Models and Managers in `Models/` and `Managers/`
+   - SwiftUI flows in `Views/`
+   - Localization and theming
+   - Data storage and import/export
+   - Notifications and background behaviors
+ - Out of scope (v1):
+   - External API SLA testing (covered by mocks/stubs)
+   - Device-specific OEM quirks beyond Apple devices
+ 
+ 
+ ## 3. Test Types and Strategy
+ - Unit tests (XCTest)
+   - Cover pure logic in `Models/` and `Managers/` (e.g., `CurrencyConverter`, `TripManager`, `TripOptimizer`, `PackingAssistant`, `ReceiptOCRManager` with stubs).
+   - Aim for ≥80% line coverage in core business logic.
+ - Integration tests
+   - Validate manager-to-manager interactions and data flow (e.g., `TripDataManager` + `DatabaseManager` + `ExportManager`).
+   - Exercise persistence and migrations if any.
+ - UI tests (XCUITest)
+   - Cover top user journeys: create/edit trip, add destinations, plan itinerary, track expenses, pack list, export, settings.
+   - Use accessibility identifiers for stable selectors.
+ - Snapshot tests (optional but recommended)
+   - Key screens in light/dark, dynamic type sizes, and localization variants.
+ - Performance tests
+   - Cold launch time, scrolling lists with many items, large receipt OCR queues, big itineraries.
+ - Localization/i18n tests
+   - Strings presence and correctness; truncation/overflows; RTL if supported.
+ - Accessibility tests
+   - VoiceOver labels, hit targets, contrast, Dynamic Type, Reduce Motion/Transparency.
+ - Offline/Resilience tests
+   - No network, flaky network, background/foreground transitions, push notification handling.
+ - Security/Privacy checks
+   - Sensitive data not logged, keychain/storage verification, permissions prompts behavior.
+ 
+ 
+ ## 4. Environments and Configurations
+ - iOS target versions: latest stable iOS and N-1 (e.g., iOS 18.x, iOS 17.x).
+ - Devices: iPhone 14/15/16 families (regular/Plus/Pro/Pro Max), iPhone SE (latest gen).
+ - Localization: At least English + one additional language from `Resources/Localizable.strings`.
+ - Appearance: Light/Dark, Dynamic Type sizes (XS–XXL).
+ - Network: Online, Offline (Airplane mode), Constrained (Low Data Mode), Proxy (mock/stub).
+ 
+ 
+ ## 5. Tooling
+ - XCTest / XCUITest for unit/integration/UI tests.
+ - Swift Package-based snapshot testing (e.g., Point-Free’s SnapshotTesting) if added.
+ - Mocks/Stubs for services (e.g., weather, OCR) via protocol-based adapters.
+ - fastlane for CI/CD lanes (optional), GitHub Actions or Xcode Cloud for CI.
+ - Instruments for performance profiling.
+ 
+ 
+ ## 6. Test Data
+ - Seeded trips covering edge cases:
+   - Short trips (1 day) vs long trips (≥30 days)
+   - Single vs multiple destinations; overlapping dates
+   - Currencies: same vs cross-currency expenses; extreme exchange rates
+   - Packing lists: empty, typical, large (100+ items)
+   - Expenses: small decimals, large amounts, multi-category
+   - OCR samples: clean receipt, skewed/low-light, multi-currency, long items
+ - Synthetic weather data via stub to test severe conditions and time ranges.
+ - Localization strings with long text to test truncation.
+ 
+ 
+ ## 7. Test Matrix (priority P1/P2/P3)
+ - iOS versions: iOS latest (P1), iOS N-1 (P1), iOS N-2 (P2 if feasible)
+ - Devices: Pro (P1), Standard (P1), SE (P2)
+ - Appearance: Light (P1), Dark (P1)
+ - Dynamic Type: Default (P1), Large (P1), Extra Large (P2)
+ - Locales: English (P1), Top secondary locale (P1), Others (P2)
+ 
+ 
+ ## 8. Core User Journeys (UI Tests)
+ - Trip lifecycle (P1)
+   1) Create a trip with name, dates, and destination(s).
+   2) Edit trip details, modify dates, add/remove destinations.
+   3) View trip list and open detail; ensure state persists across app restarts.
+ - Destination search (P1)
+   1) Search by city/country; select and add to trip.
+   2) Handle “no results” gracefully; verify recent searches/history if present.
+ - Itinerary planning (P1)
+   1) Add itinerary items with times/notes; reorder; delete.
+   2) Verify time zone handling and sorting.
+ - Packing list (P1)
+   1) Add items, mark packed/unpacked, bulk actions if available.
+   2) Large list performance and filter/search behavior.
+ - Expense tracking + insights (P1)
+   1) Add expenses in various currencies; convert and categorize.
+   2) Verify totals, averages, and charts; edge decimals/rounding.
+ - Receipt OCR (P2, stub if offline)
+   1) Import receipt image; validate extracted items and totals.
+   2) Error flows: low quality image, permission denied, retry UX.
+ - Currency converter view (P1)
+   1) Pick currencies; convert sample values; verify rounding and formatting.
+   2) Test extreme values and frequent switching.
+ - Weather forecast (P2, via stub)
+   1) Show forecast for destination dates; loading/error states.
+ - Trip optimizer (P2)
+   1) Run optimization; verify deterministic results with seeded data.
+ - Trip export/sharing (P1)
+   1) Export itinerary/packing/expenses; open share sheet; validate file content.
+ - Statistics/Analytics view (P2)
+   1) Validate aggregates and filters with seeded data.
+ - Settings (P1)
+   1) Change language/theme/currency; verify immediate UI updates and persistence.
+   2) Notifications permissions toggle; test scheduled reminders behavior.
+ 
+ 
+ ## 9. Feature-Level Test Cases (Unit/Integration)
+ - CurrencyConverter
+   - Given amount and rate, when converting, then formatting matches locale and rounding rules.
+   - Edge: zero, negative, huge values; rate precision; same currency passthrough.
+ - TripManager / TripDataManager
+   - Create/update/delete trips; concurrency safety; id uniqueness; persistence roundtrip.
+   - Sorting/filtering; date range computations; cross-feature interactions.
+ - DestinationSearchManager
+   - Query normalization; empty query; special characters; no results; caching.
+ - WeatherManager
+   - Request mapping to dates/locations; fallback behavior; stubbed errors and retries.
+ - PackingAssistant
+   - Suggestion rules based on trip length, weather, activities; dedupe logic.
+ - Expense + Insights
+   - Category totals; multi-currency normalization; daily averages; outlier handling.
+ - ReceiptOCRManager
+   - Parsing robustness; currency/locale detection; partial failures; idempotency.
+ - ExportManager
+   - File generation integrity; encoding; attachments; large exports performance.
+ - LocalizationManager
+   - Key presence; pluralization; format args; fallback to base language.
+ - SettingsManager / ThemeManager / NotificationManager
+   - Persistence; immediate effect; background/foreground transitions; permission states.
+ 
+ 
+ ## 10. Accessibility
+ - All interactive elements have accessibility labels/traits.
+ - Dynamic Type large sizes preserve layout; text not clipped.
+ - Contrast ratio meets WCAG AA; test Light/Dark themes.
+ - VoiceOver flow: key screens navigable; hints provided where needed.
+ 
+ 
+ ## 11. Performance Targets
+ - Cold launch < 2.5s on modern devices (P1).
+ - Smooth scrolling (≤16ms frame budget) with 1k+ list items (P2).
+ - OCR job processing under defined threshold on-device or via stubbed latency (P2).
+ - Export generation under 2s for medium datasets (P1), under 5s for large (P2).
+ 
+ 
+ ## 12. Automation Plan
+ - Project structure
+   - Keep tests in `Tests/` with Unit, Integration, and UI targets.
+   - Use protocols and dependency injection to enable mocking managers/services.
+ - CI
+   - Run unit + integration on each PR; UI tests nightly and on release branches.
+   - Collect coverage; fail PRs below thresholds for core modules.
+ - Reporting
+   - JUnit/XML outputs; snapshot diffs stored as artifacts.
+ - Flake mitigation
+   - Stable accessibility identifiers; retry wrappers for network-flaky UI tests; record screenshots on failure.
+ 
+ 
+ ## 13. Acceptance Criteria
+ - All P1 user journeys pass on supported iOS versions and primary device classes.
+ - Unit/Integration coverage ≥80% for core managers/models.
+ - No open P0/P1 defects; P2 defects triaged with workarounds.
+ - Accessibility essentials pass (labels, Dynamic Type, basic contrast).
+ - Performance targets met for P1 scenarios.
+ 
+ 
+ ## 14. Exit Criteria
+ - Regression suite green.
+ - Release checklist completed (localization, screenshots, marketing versioning).
+ - Sign-off by product/engineering.
+ 
+ 
+ ## 15. Risks and Mitigations
+ - OCR variability: use robust mocks, sample diversity, and manual exploratory passes.
+ - External services rate limits: test with stubs, limit live calls.
+ - Flaky UI tests: stabilize with A11y IDs and deterministic seed data.
+ - Large datasets: enforce pagination/virtualization and measure with Instruments.
+ 
+ 
+ ## 16. Manual Regression Checklist (High-Level)
+ - Create/edit/delete trip; reopen app and verify persistence.
+ - Add destinations via search; handle no-results.
+ - Manage itinerary items: add/reorder/delete; verify date/time sorting.
+ - Packing: add/complete/bulk; search/filter if present.
+ - Expenses: add in multiple currencies; verify totals and insights.
+ - OCR: import sample receipts; validate extraction; handle errors.
+ - Currency converter: switch currencies; convert edge amounts.
+ - Weather: show forecast; test error state.
+ - Export: generate and share; open exported file; verify content.
+ - Settings: language/theme change; notification toggles; verify UI updates.
+ - Accessibility: VoiceOver basic navigation; large text layout.
+ 
+ 
+ ## 17. Maintenance
+ - Update the plan when features change (see `PROJECT_SUMMARY.md` and `FEATURE_GUIDE.md`).
+ - Add new test cases alongside new features; enforce with PR template.
+ 


