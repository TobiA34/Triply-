# 🚀 Run on Your iPhone - Quick Setup

## ✅ Your iPhone is Connected!
**Device:** iPhone (18.7.1)  
**UDID:** 00008120-000C10D63E0B401E

## 📝 Setup Steps (2 minutes)

### 1. Xcode is Opening...
The project should open automatically. If not:
```bash
open Triply.xcodeproj
```

### 2. Configure Code Signing
In Xcode:
1. **Click "Triply"** (blue icon) in left sidebar
2. **Select "Triply"** target (under TARGETS)
3. **Click "Signing & Capabilities"** tab
4. ✅ **Check "Automatically manage signing"**
5. **Select your Team:**
   - If you see your Apple ID → Select it
   - If not → Click "Add Account..." → Sign in
6. Xcode will create provisioning profile automatically ✅

### 3. Select Your iPhone
- Click **device selector** (top toolbar, shows "Any iOS Device" or simulator name)
- Select **"Tobi's iPhone"** or your device name

### 4. Build & Run
- Press **`Cmd + R`** or click ▶️ Play button
- Wait for build to complete
- App will install on your iPhone

### 5. Trust Developer (First Time Only)
On your iPhone:
1. If you see "Untrusted Developer" alert
2. Go to: **Settings → General → VPN & Device Management**
3. Tap your **Apple ID** under "Developer App"
4. Tap **"Trust [Your Name]"**
5. Tap **"Trust"** to confirm
6. Run app again: **`Cmd + R`**

## ✅ Done! App is running on your iPhone!

## 🧪 Test Currency Feature
1. Open app on iPhone
2. Tap menu (⋯) → Settings
3. Tap "Currency" → Select EUR
4. Preview updates immediately ✅
5. Tap "Save"
6. Currency persists! ✅

## 🔧 If Issues

### "No signing certificate"
- Xcode → Preferences (⌘,) → Accounts
- Add your Apple ID
- Click "Download Manual Profiles"

### "Device not showing"
- Unlock iPhone
- Trust computer when iPhone asks
- Check USB cable connection

### Build fails
- Clean: `Cmd + Shift + K`
- Restart Xcode



