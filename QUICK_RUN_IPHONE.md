# Quick Guide: Run on iPhone 14 Pro

## ✅ Your iPhone is Connected!

## 🚀 Fastest Way (2 minutes)

### Step 1: Open in Xcode
```bash
open Triply.xcodeproj
```

### Step 2: Configure Signing (One-time setup)
1. Click **"Triply"** (blue project icon) in left sidebar
2. Select **"Triply"** target (under TARGETS)
3. Click **"Signing & Capabilities"** tab
4. ✅ Check **"Automatically manage signing"**
5. Select your **Team** from dropdown (your Apple ID)
   - If no team: Click "Add Account" → Sign in with Apple ID
6. Xcode will auto-create provisioning profile ✅

### Step 3: Select Your Device
- Click device selector (top toolbar, next to ▶️)
- Select **"Tobi's iPhone"** or your device name

### Step 4: Build & Run
- Press **`Cmd + R`** or click ▶️ Play button
- First time: iPhone will show "Untrusted Developer"
- On iPhone: **Settings → General → VPN & Device Management**
- Tap your Apple ID → **Trust**
- Run again: **`Cmd + R`**

## ✅ Done! App is running on your iPhone!

## 🔧 Troubleshooting

### "No signing certificate"
- Xcode → Preferences → Accounts
- Add Apple ID
- Download certificates

### "Device not showing"
- Unlock iPhone
- Trust computer when prompted
- Check USB cable
- Try different USB port

### Build errors
- Clean: `Cmd + Shift + K` in Xcode
- Restart Xcode

## 📱 Test Currency Feature
Once app is running:
1. Tap menu (⋯) → Settings
2. Tap "Currency"
3. Select EUR or any currency
4. Preview updates immediately ✅
5. Tap "Save"
6. Close and reopen → Currency persists ✅



