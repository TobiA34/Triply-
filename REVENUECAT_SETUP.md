# RevenueCat setup for Itinero

Pro subscriptions and paywall are powered by [RevenueCat](https://www.revenuecat.com). Follow these steps to finish setup.

## 1. API key (required)

The app reads the key from **Info.plist** under `RevenueCatAPIKey`.

- In [RevenueCat Dashboard](https://app.revenuecat.com) go to **Project Settings → API Keys**.
- Copy the **Public** app-specific key for iOS (starts with `appl_`).  
  Do **not** use the secret key (`sk_`) in the app.
- Set it in **Info.plist**:
  - Open `Info.plist`
  - Set `RevenueCatAPIKey` to your public key (e.g. `appl_xxxxxxxxxx`).

## 2. Entitlement (required)

Pro access is gated by an entitlement named **`pro`**.

- In RevenueCat: **Project → Entitlements**.
- Create an entitlement with identifier **`pro`** (lowercase).
- In **Products**, attach your App Store Connect subscription(s) or one-time product to this entitlement.

## 3. Offerings (for paywall price)

The paywall shows the price from RevenueCat **Offerings**.

- In RevenueCat: **Offerings**.
- Create an offering (e.g. "default") and add packages (e.g. annual, monthly).
- The app uses the **current** offering and prefers an **annual** package if present; otherwise the first available package.

## 4. App Store Connect

- Create your in-app product(s) in App Store Connect (subscription or one-time).
- In RevenueCat: **Products** → link each product to your app and attach it to the **pro** entitlement.

## 5. Build

- RevenueCat is included via **Swift Package Manager** (no CocoaPods workspace needed).
- Open **Itinero.xcodeproj** in Xcode and build. The first build will resolve the RevenueCat package.

## Troubleshooting: "RevenueCat SDK linked: no"

If the app logs **RevenueCat SDK linked: no**, Xcode built the app without the RevenueCat package. Do this:

1. **Resolve packages**  
   In Xcode: **File → Packages → Resolve Package Versions**. Wait until it finishes (check the status bar).

2. **Clean build folder**  
   **Product → Clean Build Folder** (or **Shift+Cmd+K**).

3. **Build and run**  
   **Product → Build** (or **Cmd+B**), then run the app (**Cmd+R**).

4. **If it still says "not linked"**  
   - Quit Xcode, then reopen **Itinero.xcodeproj** (not a .xcworkspace).  
   - In the Project Navigator, select the **Itinero** project (blue icon).  
   - Select the **Itinero** target → **General** → **Frameworks, Libraries, and Embedded Content**.  
   - You should see **RevenueCat**. If not, go to **Package Dependencies** and ensure **purchases-ios** (RevenueCat) is listed; add it if missing.

## Summary checklist

- [ ] `RevenueCatAPIKey` in Info.plist set to your **public** key (`appl_...`)
- [ ] Entitlement **`pro`** created in RevenueCat and products attached
- [ ] Offerings configured with at least one package
- [ ] Products linked in RevenueCat to App Store Connect

After this, the paywall will show the correct price, and purchase/restore will unlock Pro via the `pro` entitlement.
