# How to Run the App

## In Xcode (⌘R)

1. **Select the Itinero scheme** (top-left: "Itinero" next to the device dropdown).
2. **Choose a run destination:**
   - Click the device dropdown next to the scheme.
   - Pick an **iPhone** or **iPad** simulator (e.g. **iPhone 16**, **iPhone 15**, **iPad (10th generation)**).
   - Avoid "My Mac (Designed for iPad iPhone)" if Run fails.
   - If you see "iPhone 16" with no OS, pick one that shows an OS (e.g. **iPhone 16 (18.3.1)**).
3. Press **Run** (⌘R).

If you get **"Unable to find a device matching the provided destination"**:
- Pick a different simulator from the list (e.g. iPhone 15, or iPhone 16 with a specific OS like 18.3.1).
- Or: **Window → Devices and Simulators** and ensure the simulator you want is available.

## From command line

```bash
# Build for any iOS Simulator
xcodebuild -scheme Itinero -destination 'generic/platform=iOS Simulator' build

# Build and run on a specific simulator (use an id from xcodebuild -showdestinations)
xcodebuild -scheme Itinero -destination 'platform=iOS Simulator,id=6BC5A9A7-8558-4FF9-9F3B-A548211DD621' build
# Then open Simulator and launch Itinero from the home screen, or use simctl install/launch.
```

Build succeeds; if Run still fails, it’s usually the selected destination. Pick a concrete simulator and try again.
