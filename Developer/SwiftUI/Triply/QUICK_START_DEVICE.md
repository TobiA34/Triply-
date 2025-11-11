# Quick Start: Run on Your iPhone

## ✅ Your Device Detected
**iPhone (18.7.1)** - Ready to deploy!

## 🚀 Steps to Run (2 minutes)

### 1. Open in Xcode
```bash
open Triply.xcodeproj
```

### 2. Configure Signing
- Click **"Triply"** project (blue icon) in left sidebar
- Select **"Triply"** target
- Go to **"Signing & Capabilities"** tab
- ✅ Check **"Automatically manage signing"**
- Select your **Team** (your Apple ID)
- Xcode will auto-create provisioning profile

### 3. Select Your Device
- Click device selector (top toolbar, next to play button)
- Select **"Tobi's iPhone"** or your device name

### 4. Build & Run
- Press **`Cmd + R`** or click ▶️ Play button
- First time: Device will show "Untrusted Developer"
- On iPhone: **Settings → General → VPN & Device Management**
- Tap your Apple ID → **Trust**
- Run again: **`Cmd + R`**

## ✅ Done!
App will install and launch on your iPhone.

## 🔧 If Issues

### "No signing certificate"
- Xcode → Preferences → Accounts
- Add your Apple ID
- Download certificates

### Build errors
- Clean: `Cmd + Shift + K`
- Restart Xcode

### Device not showing
- Unlock iPhone
- Trust computer when prompted
- Check USB cable

## 📱 Testing Currency Feature
Once app is running:
1. Open **Settings** (menu → Settings)
2. Tap **"Currency"**
3. Select **EUR** or any currency
4. Tap **"Save"**
5. Check preview updates immediately
6. Close and reopen Settings → Currency should persist!



