#!/bin/bash
# Script to help configure App Groups in Xcode project

echo "🔧 App Groups Configuration Helper"
echo "=================================="
echo ""
echo "This script helps verify App Groups setup."
echo ""
echo "⚠️  IMPORTANT: You MUST configure App Groups in Xcode manually!"
echo ""
echo "Steps to configure App Groups:"
echo ""
echo "1. Open Xcode:"
echo "   open Triply.xcodeproj"
echo ""
echo "2. For MAIN APP (Triply target):"
echo "   - Select 'Triply' target in Project Navigator"
echo "   - Go to 'Signing & Capabilities' tab"
echo "   - Click '+ Capability' button"
echo "   - Search for 'App Groups'"
echo "   - Add it"
echo "   - Click '+' under App Groups section"
echo "   - Enter: group.com.ntriply.app"
echo "   - Press Enter"
echo ""
echo "3. For WIDGET EXTENSION (TriplyWidgetExtensionExtension target):"
echo "   - Select 'TriplyWidgetExtensionExtension' target"
echo "   - Go to 'Signing & Capabilities' tab"
echo "   - Click '+ Capability' button"
echo "   - Search for 'App Groups'"
echo "   - Add it"
echo "   - Click '+' under App Groups section"
echo "   - Enter: group.com.ntriply.app (SAME as main app!)"
echo "   - Press Enter"
echo ""
echo "4. Verify both targets show:"
echo "   ✅ App Groups"
echo "   ✅ group.com.ntriply.app"
echo ""
echo "5. Clean and rebuild:"
echo "   - Product → Clean Build Folder (Shift+⌘+K)"
echo "   - Product → Build (⌘+B)"
echo ""
echo "6. Delete app from device/simulator and reinstall"
echo ""
echo "=================================="
echo "Checking current configuration..."
echo ""

# Check if entitlements files exist
if [ -f "Triply.entitlements" ]; then
    echo "✅ Main app entitlements file exists"
    if grep -q "group.com.ntriply.app" "Triply.entitlements"; then
        echo "✅ Main app entitlements contains App Group"
    else
        echo "❌ Main app entitlements missing App Group"
    fi
else
    echo "❌ Main app entitlements file missing"
fi

if [ -f "TriplyWidgetExtension/TriplyWidgetExtension.entitlements" ]; then
    echo "✅ Widget extension entitlements file exists"
    if grep -q "group.com.ntriply.app" "TriplyWidgetExtension/TriplyWidgetExtension.entitlements"; then
        echo "✅ Widget extension entitlements contains App Group"
    else
        echo "❌ Widget extension entitlements missing App Group"
    fi
else
    echo "❌ Widget extension entitlements file missing"
fi

echo ""
echo "Note: Entitlements files are just configuration."
echo "You MUST add App Groups capability in Xcode for it to work!"
echo ""








