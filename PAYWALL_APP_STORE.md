# Paywall checklist for App Store Connect

Before uploading to App Store Connect, complete these steps so the paywall and in-app purchases pass review.

## 1. RevenueCat

- In **Info.plist**, replace the test `RevenueCatAPIKey` with your **production** API key from the RevenueCat dashboard (Project → API Keys).
- In RevenueCat dashboard, ensure your **production** App Store Connect app and in-app products are linked and the entitlement is set up.

## 2. Terms of Use and Privacy Policy

- In **Info.plist**, replace the placeholder URLs:
  - `AppTermsOfUseURL` → your real Terms of Use URL (e.g. `https://yourapp.com/terms`).
  - `AppPrivacyPolicyURL` → your real Privacy Policy URL (e.g. `https://yourapp.com/privacy`).
- If these keys are missing or still set to `https://example.com/terms` or `https://example.com/privacy`, the links will not appear on the paywall (legal text will still show). Apple requires Terms and Privacy links for apps with auto-renewable subscriptions.

## 3. App Store Connect

- Create your **in-app purchase** product(s) (subscription or one-time) and attach them to your app.
- In **App Store Connect → App → App Information**, set your **Privacy Policy URL** (required for apps with IAP/subscriptions).
- In **App Store Connect → Agreements, Tax, and Banking**, complete the **Paid Applications** agreement and banking/tax if you are selling IAP.

## 4. What’s already handled in the app

- **Close button** – Users can dismiss the paywall without purchasing.
- **Restore Purchases** – Shown on the paywall; “Manage subscription” is available in Settings when the user is Pro.
- **Subscription legal text** – Full renewal/cancellation/charge text is shown when you offer subscriptions (multiple packages).
- **User-facing errors** – Technical or sandbox error messages are replaced with generic messages in release builds.
- **DEBUG-only code** – The “Debug: Unlock Pro” button is compiled out in release (`#if DEBUG`).

After updating the API key and URLs, build with a **Release** configuration and test the paywall and restore flow before submitting.
