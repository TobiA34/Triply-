# Running Triply on Physical Device

## Prerequisites
1. **Apple Developer Account** (Free or Paid)
2. **Xcode** installed
3. **iPhone/iPad** connected via USB
4. **Trust Computer** on your device when prompted

## Steps to Run on Physical Device

### 1. Open Project in Xcode
```bash
open Triply.xcodeproj
```

### 2. Select Your Device
- In Xcode, click the device selector (next to the play button)
- Select your connected iPhone/iPad
- If device doesn't appear:
  - Make sure it's unlocked
  - Trust the computer on device
  - Check USB connection

### 3. Configure Signing
- Click on "Triply" project in navigator
- Select "Triply" target
- Go to "Signing & Capabilities" tab
- Check "Automatically manage signing"
- Select your Team (Apple ID)
- Xcode will create a provisioning profile

### 4. Build and Run
- Press `Cmd + R` or click the Play button
- First time: Device will ask to trust developer
- Go to: Settings → General → VPN & Device Management
- Tap your Apple ID → Trust
- Run again

### 5. Alternative: Command Line
```bash
# List connected devices
xcrun xctrace list devices

# Build for device (replace DEVICE_UDID with your device UDID)
xcodebuild -project Triply.xcodeproj \
  -scheme Triply \
  -destination 'id=DEVICE_UDID' \
  build

# Install on device
xcrun devicectl device install app --device DEVICE_UDID /path/to/app.ipa
```

## Troubleshooting

### "No signing certificate found"
- Go to Xcode → Preferences → Accounts
- Add your Apple ID
- Download certificates

### "Device not trusted"
- On device: Settings → General → VPN & Device Management
- Trust your developer certificate

### "Unable to install app"
- Check device has enough storage
- Make sure device is unlocked
- Restart Xcode and device

### Build Errors
- Clean build folder: `Cmd + Shift + K`
- Delete DerivedData
- Restart Xcode

## Quick Test Commands

```bash
# Check connected devices
xcrun xctrace list devices

# Build for generic iOS device
xcodebuild -project Triply.xcodeproj -scheme Triply -destination 'generic/platform=iOS' build

# Check code signing
security find-identity -v -p codesigning
```



