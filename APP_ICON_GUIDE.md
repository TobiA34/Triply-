# App Icon Setup Guide

## Quick Setup

### Option 1: Use Xcode (Recommended)
1. Open `Triply.xcodeproj` in Xcode
2. Navigate to `Assets.xcassets` → `AppIcon`
3. Drag and drop your 1024x1024 icon image
4. Xcode will automatically generate all required sizes

### Option 2: Manual Setup
1. Create a 1024x1024 PNG icon image
2. Name it `Icon-1024.png`
3. Place it in `Assets.xcassets/AppIcon.appiconset/`
4. Xcode will auto-generate other sizes, or use an icon generator tool

## Required Icon Sizes

The app icon requires these sizes:

### iPhone
- 20x20 @2x (40x40px)
- 20x20 @3x (60x60px)
- 29x29 @2x (58x58px)
- 29x29 @3x (87x87px)
- 40x40 @2x (80x80px)
- 40x40 @3x (120x120px)
- 60x60 @2x (120x120px)
- 60x60 @3x (180x180px)

### iPad
- 20x20 @1x (20x20px)
- 20x20 @2x (40x40px)
- 29x29 @1x (29x29px)
- 29x29 @2x (58x58px)
- 40x40 @1x (40x40px)
- 40x40 @2x (80x80px)
- 76x76 @1x (76x76px)
- 76x76 @2x (152x152px)
- 83.5x83.5 @2x (167x167px)

### App Store
- 1024x1024 @1x (1024x1024px) - **Required**

## Icon Design Tips

- Use a simple, recognizable design
- Ensure it looks good at small sizes
- Avoid text (it becomes unreadable)
- Use high contrast colors
- Test on both light and dark backgrounds
- Follow Apple's Human Interface Guidelines

## Online Icon Generators

You can use these tools to generate all sizes from a single 1024x1024 image:
- [AppIcon.co](https://www.appicon.co/)
- [IconKitchen](https://icon.kitchen/)
- [MakeAppIcon](https://makeappicon.com/)

## Current Status

The `Contents.json` is configured with all required sizes. You just need to add the actual icon images.

