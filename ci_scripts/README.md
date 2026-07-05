# Xcode Cloud CI Scripts

This folder is used by **Xcode Cloud** for optional custom build steps. Scripts here run in the cloud build environment.

## Optional script hooks

| Script | When it runs |
|--------|----------------|
| `ci_post_clone.sh` | After the repo is cloned (e.g. install dependencies) |
| `ci_pre_xcodebuild.sh` | Before `xcodebuild` runs |
| `ci_post_xcodebuild.sh` | After `xcodebuild` completes |

## Do you need these?

- **Swift Package Manager** dependencies are resolved automatically by Xcode; you usually don’t need `ci_post_clone.sh`.
- Use `ci_post_clone.sh` if you need to run **CocoaPods** (`pod install`), install tools via Homebrew, or set up secrets/keys.
- Keep scripts **executable** (`chmod +x ci_*.sh`) and **idempotent** so builds are reliable.

## Example: CocoaPods (if you use Pods)

```bash
#!/bin/sh
set -e
if [ -f "Podfile" ]; then
  brew install cocoapods
  pod install
fi
```

## More info

- [Writing custom build scripts (Apple)](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Making dependencies available to Xcode Cloud](https://developer.apple.com/documentation/xcode/making-dependencies-available-to-xcode-cloud)
