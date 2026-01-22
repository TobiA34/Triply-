# RevenueCat Setup Guide

## ✅ What's Been Done

1. **StoreKit Configuration File Updated** (`Triply.storekit`)
   - Added three subscription products:
     - `triply_pro_monthly` - £4.99/month (Auto-Renewable Subscription)
     - `triply_pro_annual` - £39.99/year (Auto-Renewable Subscription)
     - `triply_pro_lifetime` - £99.99 (Non-Consumable, one-time purchase)
   - Created subscription group: `triply_pro_subscriptions`

2. **RevenueCat Manager Configured**
   - Product IDs match the StoreKit configuration
   - Entitlement ID: `pro`
   - API Key configured in Info.plist

## 🔧 Next Steps: Configure RevenueCat Dashboard

**Important**: For local testing, you don't need App Store Connect! The StoreKit Configuration file is enough.

### Step 1: Add Products in RevenueCat Dashboard

1. Go to https://app.revenuecat.com
2. Select your app (or create one if you haven't)
3. Navigate to **Products** in the left sidebar
4. Click **+ New** to add each product:

   **Product 1: Monthly Subscription**
   - Product Identifier: `triply_pro_monthly`
   - Store: App Store
   - **Note**: RevenueCat will automatically detect it's a subscription from your StoreKit file. You don't need to select a "type" - just enter the ID!

   **Product 2: Annual Subscription**
   - Product Identifier: `triply_pro_annual`
   - Store: App Store

   **Product 3: Lifetime Purchase**
   - Product Identifier: `triply_pro_lifetime`
   - Store: App Store

### Step 2: Create an Entitlement

1. Navigate to **Entitlements** in the left sidebar
2. Click **+ New** to create an entitlement:
   - Identifier: `pro`
   - Attach all three products to this entitlement

### Step 3: Create an Offering

1. Navigate to **Offerings** in the left sidebar
2. Click **+ New** to create an offering:
   - Identifier: `default` (or any name you prefer)
   - Set as **Current Offering** (this is what RevenueCat will fetch)
   - Add packages:
     - Package 1: Monthly subscription (`triply_pro_monthly`)
     - Package 2: Annual subscription (`triply_pro_annual`)
     - Package 3: Lifetime purchase (`triply_pro_lifetime`)

### Step 4: Verify API Key

1. Go to **Project Settings** → **API Keys**
2. Make sure you're using the **Public SDK Key** (starts with `appl_` or `rcapp_`)
3. Verify it matches the key in your `Info.plist` under `RevenueCatAPIKey`

## 🧪 Testing Locally (No App Store Connect Needed!)

For local testing, you only need the StoreKit Configuration file. Here's how:

1. **Enable StoreKit Testing in Xcode**:
   - In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
   - Select **Run** → **Options** tab
   - Under **StoreKit Configuration**, select `Triply.storekit`
   - Click **Close**

2. **Configure RevenueCat for Local Testing**:
   - In RevenueCat dashboard, when adding products, RevenueCat will try to fetch them from App Store Connect
   - **For local testing**: RevenueCat will use your StoreKit file automatically when testing in Xcode
   - Just add the product IDs in RevenueCat (even if they don't exist in App Store Connect yet)

3. **Build and Run**:
   - Build and run the app
   - RevenueCat will use the StoreKit Configuration file for testing

**Note**: If RevenueCat shows an error about products not being found, that's okay for local testing. The StoreKit file will still work when you run the app in Xcode with the StoreKit configuration enabled.

## 📝 Important Notes

### For Local Testing (Now):
- ✅ **StoreKit Configuration file is enough** - No App Store Connect needed!
- ✅ Just add product IDs in RevenueCat dashboard
- ✅ Enable StoreKit Configuration in Xcode scheme

### For Production (Later):
- You'll need to create these products in **App Store Connect**:
  1. Go to App Store Connect → Your App → **Subscriptions**
  2. Create a **Subscription Group** (e.g., "Itinero Pro")
  3. Add subscriptions:
     - Monthly subscription (`triply_pro_monthly`)
     - Annual subscription (`triply_pro_annual`)
  4. For lifetime purchase, go to **In-App Purchases** → **Non-Consumable** → Add `triply_pro_lifetime`

- **Product IDs**: Must match exactly between:
  - StoreKit Configuration file
  - RevenueCat Dashboard  
  - App Store Connect (for production)

- **Pricing**: The prices in the StoreKit file are for testing. Set actual prices in App Store Connect for production.

## 🔍 Troubleshooting

If you still see errors:

1. **Check API Key**: Verify the key in Info.plist matches your RevenueCat dashboard
2. **Check Product IDs**: Ensure they match exactly (case-sensitive)
3. **Check Entitlement**: Make sure the entitlement `pro` exists and has products attached
4. **Check Offering**: Verify you have a current offering configured
5. **Check StoreKit File**: In Xcode, verify the StoreKit file is selected in the scheme

## 📚 Resources

- RevenueCat Dashboard: https://app.revenuecat.com
- RevenueCat Docs: https://docs.revenuecat.com
- Why Offerings Empty: https://rev.cat/why-are-offerings-empty

