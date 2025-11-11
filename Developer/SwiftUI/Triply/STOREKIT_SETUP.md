# StoreKit Configuration Guide

## Product ID Verification

The app uses the product ID: **`com.triply.app.pro`**

This is configured in:
1. `Info.plist` → `IAPProductProId` key
2. `IAPManager.swift` → `ProductID.pro` enum
3. `Triply.storekit` → StoreKit configuration file

## Setting Up StoreKit Testing in Xcode

### Step 1: Enable StoreKit Configuration
1. Open `Triply.xcodeproj` in Xcode
2. Select the **Triply** scheme (top toolbar)
3. Click **Edit Scheme...**
4. Go to **Run** → **Options** tab
5. Under **StoreKit Configuration**, select **Triply.storekit**
6. Click **Close**

### Step 2: Test In-App Purchase
1. Run the app in the simulator or on a device
2. Navigate to **Settings** → **Customize Theme**
3. Try to create more than 1 theme (Free tier limit)
4. Tap **"Upgrade to Pro"**
5. The StoreKit testing interface will appear
6. Complete the purchase (no real charge in testing mode)

### Step 3: Verify Product ID in App Store Connect (For Production)

When ready for production:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Features** → **In-App Purchases**
3. Create a new **Non-Consumable** product
4. Set Product ID to: **`com.triply.app.pro`**
5. Complete product information and pricing
6. Submit for review

## Current Configuration

- **Product ID**: `com.triply.app.pro`
- **Product Type**: Non-Consumable (one-time purchase)
- **StoreKit Config**: `Triply.storekit` (for local testing)
- **Price**: $9.99 (configured in StoreKit file, update in App Store Connect for production)

## Troubleshooting

### "Product not found" Error

**If using StoreKit Configuration (local testing):**
- Ensure `Triply.storekit` is selected in scheme settings
- Verify product ID matches: `com.triply.app.pro`
- Check that StoreKit config file is included in project resources

**If using App Store Connect (production/sandbox):**
- Verify product ID matches exactly: `com.triply.app.pro`
- Ensure product is in "Ready to Submit" or "Approved" status
- Check that you're signed in with a Sandbox tester account (for testing)
- Verify bundle ID matches: `com.triply.app`

### Debug Unlock (Development Only)

In DEBUG builds, you can unlock Pro without a purchase:
- The paywall shows a "Debug: Unlock Pro" button
- This only works in DEBUG mode, not in production builds

## Testing Checklist

- [ ] StoreKit configuration file added to project
- [ ] Scheme configured to use `Triply.storekit`
- [ ] Product ID verified: `com.triply.app.pro`
- [ ] Test purchase works in simulator
- [ ] Restore purchases works
- [ ] Pro tier unlocks unlimited themes
- [ ] Theme creation respects tier limits

