# RevenueCat Quick Setup (For Testing)

## ✅ Good News: No App Store Connect Needed for Testing!

For local testing, you **don't need App Store Connect**. The StoreKit Configuration file (`Triply.storekit`) is enough!

## 🚀 Quick Setup (3 Steps)

### Step 1: Enable StoreKit in Xcode

1. In Xcode: **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options** tab
3. Under **StoreKit Configuration**, select `Triply.storekit`
4. Click **Close**

### Step 2: Add Products in RevenueCat Dashboard

1. Go to https://app.revenuecat.com
2. Select your app (or create one)
3. Go to **Products** → Click **+ New**
4. **Just enter the Product Identifier** - that's it! No need to select a "type":
   - `triply_pro_monthly`
   - `triply_pro_annual`
   - `triply_pro_lifetime`

**Note**: RevenueCat doesn't have a "type" dropdown. It automatically detects the type from your StoreKit file or App Store Connect. Just enter the ID!

### Step 3: Create Entitlement & Offering

1. **Create Entitlement**:
   - Go to **Entitlements** → **+ New**
   - Identifier: `pro`
   - Attach all three products

2. **Create Offering**:
   - Go to **Offerings** → **+ New**
   - Identifier: `default`
   - Set as **Current Offering**
   - Add all three packages

## 🧪 Test It

1. Build and run your app
2. The StoreKit file will be used automatically
3. RevenueCat will load the offerings from your StoreKit configuration

## ❓ What About App Store Connect?

**For Testing**: Not needed! The StoreKit file is enough.

**For Production** (when you're ready to release):
- You'll create subscriptions in App Store Connect later
- For now, just use the StoreKit file for testing

## 🔍 If You Still See Errors

RevenueCat might show warnings about products not being in App Store Connect - that's **normal for testing**. As long as:
- ✅ StoreKit Configuration is enabled in Xcode scheme
- ✅ Products are added in RevenueCat dashboard
- ✅ Entitlement and Offering are created

The app should work for local testing!

