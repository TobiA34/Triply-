# Xcode Cloud Setup for Itinero (Triply)

This guide walks you through setting up **Xcode Cloud** so you can build, test, and **send releases to the App Store** automatically.

## Prerequisites

- **Apple Developer Program** membership
- **Xcode 15 or later** on your Mac
- **App record** for Itinero in [App Store Connect](https://appstoreconnect.apple.com/) (create one if you haven’t)
- **Git repo** hosted on **GitHub**, **GitLab**, or **Bitbucket** (Xcode Cloud must connect to a remote)
- **Automatic code signing** enabled for the Itinero target (already set in this project)
- **Shared scheme** “Itinero” with **Archive** enabled (already configured)

## 1. Push your project to a supported Git host

Xcode Cloud only works with a **remote** repository:

- Push your repo to **GitHub**, **GitLab**, or **Bitbucket** (or your org’s instance).
- Ensure you have **admin** (or equivalent) access so you can connect the repo to Xcode Cloud.

## 2. Add your Apple ID in Xcode

1. Open **Xcode** → **Settings…** (or **Preferences…**) → **Accounts**.
2. Add your **Apple ID** used for the Apple Developer Program.
3. Select your **Team** (e.g. the one that owns `com.ntriply.app`).

## 3. Create your first Xcode Cloud workflow

1. Open **`Itinero.xcodeproj`** in Xcode.
2. Open the **Report navigator** (last tab in the left sidebar, or **View → Navigators → Report**).
3. Click the **Cloud** (Xcode Cloud) button at the top.
4. Click **Get Started** (or **Create Workflow**).
5. **Select product**: choose **Itinero** (the main app).
6. **Grant access**: when prompted, click **Grant Access** and complete the OAuth flow for your Git host (GitHub/GitLab/Bitbucket) so Xcode Cloud can read your repo.
7. **Create app record** (if needed): if you don’t have an app in App Store Connect yet, follow the prompts to create one; use bundle ID **`com.ntriply.app`**.
8. **Review the suggested workflow** (branch, scheme, actions). Keep the default if you’re unsure.
9. Click **Start Build** to run the first build and confirm everything works.

## 4. Add App Store / TestFlight distribution (release automation)

To **automatically send builds to TestFlight** (and then submit to the App Store from App Store Connect):

1. In the Report navigator, click the **Cloud** button.
2. **Manage Workflows** (or double‑click the workflow you created).
3. **Edit** the workflow you use for release.
4. In the workflow editor, find **Post-Actions** (or **Actions** → **Post-Actions**).
5. Add a **Distribute App** (or **Upload to App Store Connect**) post-action:
   - **Destination**: **App Store Connect** (TestFlight).
   - Optionally enable **Submit for TestFlight review** so external testers get the build without a manual step.
6. Save the workflow.

Now, whenever this workflow runs (e.g. on push to `main` or a “release” branch), Xcode Cloud will:

- Build and archive the app  
- Upload the build to App Store Connect  
- Make it available in **TestFlight** (and you can then submit that build to the App Store from App Store Connect)

## 5. When do builds run? (Start conditions)

In the same workflow editor you can set **Start Conditions**:

- **Branch**: e.g. run only when pushing to `main` or `release`.
- **Pull requests**: optionally run on PRs targeting that branch.

Example for a simple “release” pipeline:

- Start condition: **Branch** → `main` (or `release`).
- Post-action: **Distribute App** → App Store Connect.

So: **push to `main`** → Xcode Cloud builds → uploads to TestFlight → you submit to the App Store from App Store Connect when ready.

## 5b. Release with one command

After the workflow has the **Distribute App** post-action (section 4), you can trigger a release in either of these ways:

**Option A – Push to the branch (simplest)**  
If the workflow starts on push to `main` (or your release branch):

```bash
git push origin main
```

That starts the workflow; when it finishes, the build is in App Store Connect (TestFlight).

**Option B – Trigger from the command line (no push)**  
Use the App Store Connect API to start the workflow yourself:

1. Create an [App Store Connect API key](https://appstoreconnect.apple.com/access/api) (Admin/App Manager/Developer role), download the `.p8` file, and note **Issuer ID** and **Key ID**.
2. Install deps and set env:

```bash
pip3 install pyjwt requests
export ASC_ISSUER_ID="your-issuer-id"
export ASC_KEY_ID="your-key-id"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXX.p8"
```

3. Run the script (default branch `main`, or pass a branch name):

```bash
python3 Scripts/trigger_xcode_cloud_release.py
# or
python3 Scripts/trigger_xcode_cloud_release.py main
```

The script starts the Xcode Cloud workflow; when the run completes, the **Distribute App** post-action uploads to App Store Connect. See `Scripts/trigger_xcode_cloud_release.py` for details (e.g. repo name `Triply-`).

## 6. Sending a release to the App Store (summary)

1. **Version / build number**: Update **Marketing Version** or **Current Project Version** in Xcode (or in the target’s **General** tab) if you want a new version/build.
2. **Commit and push** to the branch that triggers your Xcode Cloud workflow (e.g. `main`).
3. **Wait for the build** in Xcode (Report navigator → Cloud) or in [App Store Connect](https://appstoreconnect.apple.com/) → your app → **Xcode Cloud** (or **TestFlight**).
4. In **App Store Connect** → **TestFlight** (or **App Store**): select the new build and **Submit for Review** to send the release to the App Store.

## 7. Optional: CI scripts

If you need to install dependencies (e.g. CocoaPods) or run custom steps in the cloud, add scripts under **`ci_scripts/`**:

- `ci_post_clone.sh` – runs after clone (e.g. `pod install`).
- `ci_pre_xcodebuild.sh` – runs before `xcodebuild`.
- `ci_post_xcodebuild.sh` – runs after `xcodebuild`.

See **`ci_scripts/README.md`** for details. For a Swift Package Manager–only project, you usually don’t need these.

## 8. Useful links

- [Requirements for using Xcode Cloud](https://developer.apple.com/documentation/xcode/requirements-for-using-xcode-cloud)
- [Configuring your first Xcode Cloud workflow](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [Xcode Cloud workflow reference](https://developer.apple.com/documentation/xcode/xcode-cloud-workflow-reference)
- [App Store Connect](https://appstoreconnect.apple.com/)

## Troubleshooting

### “Unable to grant Xcode Cloud access to your repository” (GitHub)

This usually means Xcode Cloud couldn’t get the right permissions to your GitHub repo. Try these in order:

1. **Use the correct GitHub account**
   - In Xcode: **Settings → Accounts**. Under **GitHub**, ensure the account that **owns** the repo (`TobiA34/Triply-`) is listed and selected when you click **Grant Access**.
   - If you have multiple GitHub accounts, remove the wrong one or add the right one, then try **Grant Access** again.

2. **Confirm you have admin on the repo**
   - For a **personal repo** (e.g. `TobiA34/Triply-`): you must be the owner (you have admin by default).
   - For an **organization repo**: you must be an **organization owner** (not just “admin” of the repo). If you’re not an org owner, an owner must do the “Grant Access” step, or use [admin-managed repository setup](https://developer.apple.com/documentation/xcode/connecting-xcode-cloud-to-an-admin-managed-git-repository).

3. **Install / re-authorize the GitHub App for this repo**
   - In a browser, go to **GitHub → Settings → Applications → Installed GitHub Apps** (or [github.com/settings/installations](https://github.com/settings/installations)).
   - Find **Xcode Cloud** (or **Apple**) and open it.
   - Ensure **Triply-** (or the exact repo name) is **selected** under “Repository access”. If it says “All repositories”, that’s fine; if “Only select repositories”, your repo must be in the list.
   - If you don’t see Xcode Cloud, the OAuth flow may not have finished. Try **Grant Access** again in Xcode and complete the browser flow until GitHub shows the app.
   - Optional: **Uninstall** the Xcode Cloud app for your account, then in Xcode run the workflow setup again and click **Grant Access** to go through the install flow from scratch.

4. **Open the same project Xcode Cloud will use**
   - Open **`Itinero.xcodeproj`** (the project), not only a workspace. In the workflow setup, Xcode infers the repo from the open project; if the workspace points elsewhere, the “correct repository” can be wrong.

5. **Grant access from App Store Connect**
   - Sometimes the connection works better when started from the web: go to [App Store Connect](https://appstoreconnect.apple.com/) → your app → **Xcode Cloud** tab. If you see an option to connect or manage the repository, use it and complete the GitHub authorization there. Then return to Xcode and try **Get Started** or **Manage Workflows** again.

6. **Repository name and URL**
   - Your repo is `https://github.com/TobiA34/Triply-` (note the hyphen). When GitHub asks “Which repository?”, pick **TobiA34/Triply-** explicitly. If you had an old repo (e.g. without the hyphen), make sure you’re not selecting the wrong one.

7. **Browser and cookies**
   - Use a normal browser window (not strict private/incognito), allow cookies for GitHub and Apple, and avoid VPN/proxy when clicking **Grant Access** so the redirect back to Xcode completes.

If it still fails, use [Connect Xcode Cloud to GitHub](https://developer.apple.com/documentation/xcode/connecting-xcode-cloud-to-github) and the [Apple Developer Forums (Xcode Cloud)](https://developer.apple.com/forums/) for the latest steps and known issues.

---

- **“No products to build”**: Ensure the **Itinero** scheme is **shared** (Scheme → **Manage Schemes…** → check **Shared** for Itinero) and that **Archive** is enabled for the app target in that scheme.
- **Signing errors**: Confirm **Signing & Capabilities** for the Itinero target uses **Automatically manage signing** and the correct **Team**.
- **Widget / extension**: The **TriplyWidgetExtension** target uses the same team and automatic signing; ensure its bundle ID (`com.ntriply.app.TriplyWidgetExtension`) is registered in your Apple Developer account (Identifiers).
- **Build time**: Apple includes a set amount of Xcode Cloud build time per month; check [Get started with Xcode Cloud](https://developer.apple.com/xcode-cloud/get-started/) for current limits and subscription options.
