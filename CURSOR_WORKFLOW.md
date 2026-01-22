# Working in Cursor - Complete Guide

## 🎯 Overview

You can develop entirely in Cursor and run the SwiftUI app from the terminal! No need to open Xcode (except for initial setup).

## ⚠️ Important Note

SwiftUI iOS apps **require Xcode command-line tools** to build, but you don't need to open Xcode itself. The tools are installed with Xcode.

## 🚀 Quick Start

### 1. Build and Run (One Command)

```bash
./run.sh
```

This will:
- Build your app
- Launch iOS Simulator
- Install and run the app
- Keep it running

### 2. Just Build

```bash
./build.sh
```

### 3. Watch Mode (Auto-rebuild on changes)

```bash
./watch.sh
```

Then edit files in Cursor - it auto-rebuilds!

## 📋 Available Scripts

| Script | Purpose |
|--------|---------|
| `./run.sh` | Build + Run app in simulator |
| `./build.sh` | Just build (no run) |
| `./watch.sh` | Auto-rebuild on file changes |
| `./open_in_xcode.sh` | Open in Xcode (for previews) |

## 🛠️ Setup (First Time Only)

### Install fswatch (for watch mode)

```bash
brew install fswatch
```

### Make Scripts Executable

```bash
chmod +x *.sh
```

## 💻 Development Workflow

### Recommended Workflow

1. **Edit code in Cursor** - Use all Cursor's AI features
2. **Run from terminal**:
   ```bash
   ./run.sh
   ```
3. **See changes** - App runs in Simulator
4. **Iterate** - Edit, rebuild, test

### Watch Mode Workflow

1. **Start watch mode**:
   ```bash
   ./watch.sh
   ```
2. **Edit files in Cursor**
3. **Auto-rebuilds** when you save
4. **Manually run** when ready: `./run.sh`

## 🎨 SwiftUI Previews

Unfortunately, **SwiftUI Previews only work in Xcode**. But you can:

1. **Use the simulator** - Run `./run.sh` to see your UI
2. **Quick preview in Xcode** - Run `./open_in_xcode.sh` when you want previews
3. **Work in Cursor, preview in Xcode** - Best of both worlds!

## 🔧 Troubleshooting

### "xcodebuild: command not found"

Install Xcode command-line tools:
```bash
xcode-select --install
```

### "Simulator not found"

List available simulators:
```bash
xcrun simctl list devices available
```

Then edit `run.sh` and change the `SIMULATOR` variable.

### Build Errors

Check the error output. Common issues:
- Missing files in Xcode project
- Syntax errors (Cursor will show these)
- Missing dependencies

### App Not Launching

Try:
```bash
# Clean build
xcodebuild clean -project Triply.xcodeproj -scheme Triply

# Then rebuild
./run.sh
```

## 📱 Simulator Controls

Once the app is running:

- **Stop app**: Close Simulator or `Ctrl+C` in terminal
- **Restart app**: Run `./run.sh` again
- **Change simulator**: Edit `SIMULATOR` in `run.sh`

## 🎯 Tips

1. **Keep Simulator open** - Faster iterations
2. **Use watch mode** - Auto-rebuilds save time
3. **Terminal split** - Keep terminal visible while coding
4. **Quick test** - `./build.sh` to just check compilation

## 🔄 Complete Workflow Example

```bash
# Terminal 1: Watch mode
./watch.sh

# Terminal 2: Run when ready
./run.sh

# Cursor: Edit code
# - Make changes
# - Save file
# - Watch mode rebuilds automatically
# - Run again to see changes
```

## ✅ Advantages of This Setup

- ✅ Work entirely in Cursor
- ✅ Use all Cursor AI features
- ✅ No need to switch to Xcode
- ✅ Fast iteration with watch mode
- ✅ Terminal-based workflow
- ✅ Can still use Xcode for previews when needed

## 🚀 You're Ready!

Start developing:

```bash
./run.sh
```

Happy coding in Cursor! 🎉



