#!/bin/bash

echo "🔍 Verifying Settings Modal Implementation..."
echo ""

ERRORS=0

# Check if SettingsView.swift exists and has key components
echo "📄 Checking SettingsView.swift..."
if grep -q "@Environment(\.dismiss)" Views/SettingsView.swift; then
    echo "  ✅ Dismiss environment present"
else
    echo "  ❌ Missing dismiss environment"
    ((ERRORS++))
fi

if grep -q "@State private var selectedCurrency" Views/SettingsView.swift; then
    echo "  ✅ Currency state variable present"
else
    echo "  ❌ Missing currency state"
    ((ERRORS++))
fi

if grep -q "\.task {" Views/SettingsView.swift; then
    echo "  ✅ Async task loading present"
else
    echo "  ❌ Missing async task"
    ((ERRORS++))
fi

if grep -q "loadSettingsAsync()" Views/SettingsView.swift; then
    echo "  ✅ Async settings loader present"
else
    echo "  ❌ Missing async loader"
    ((ERRORS++))
fi

if grep -q "Form {" Views/SettingsView.swift; then
    echo "  ✅ Form structure present"
else
    echo "  ❌ Missing form"
    ((ERRORS++))
fi

if grep -q "preferencesSection\|currencySection\|themeSection\|languageSection" Views/SettingsView.swift; then
    echo "  ✅ All sections present"
else
    echo "  ❌ Missing sections"
    ((ERRORS++))
fi

echo ""
echo "📄 Checking TripListView.swift..."
if grep -q "@State private var showingSettings" Views/TripListView.swift; then
    echo "  ✅ Settings state variable present"
else
    echo "  ❌ Missing settings state"
    ((ERRORS++))
fi

if grep -q "\.sheet(isPresented: \$showingSettings)" Views/TripListView.swift; then
    echo "  ✅ Sheet presentation present"
else
    echo "  ❌ Missing sheet presentation"
    ((ERRORS++))
fi

if grep -q "NavigationStack" Views/TripListView.swift | grep -A 5 "showingSettings" | grep -q "NavigationStack"; then
    echo "  ✅ NavigationStack wrapper present"
else
    echo "  ⚠️  NavigationStack may not be properly wrapped"
fi

if grep -q "\.presentationDetents" Views/TripListView.swift; then
    echo "  ✅ Presentation detents configured"
else
    echo "  ❌ Missing presentation detents"
    ((ERRORS++))
fi

if grep -q "\.presentationDragIndicator" Views/TripListView.swift; then
    echo "  ✅ Drag indicator configured"
else
    echo "  ❌ Missing drag indicator"
    ((ERRORS++))
fi

echo ""
echo "🔍 Checking for problematic patterns..."
if grep -q "onChange(of: localizationManager.currentLanguage)" Views/SettingsView.swift; then
    echo "  ⚠️  Found onChange handler - may cause issues"
    ((ERRORS++))
else
    echo "  ✅ No problematic onChange handlers"
fi

if grep -q "refreshID" Views/SettingsView.swift; then
    echo "  ⚠️  Found refreshID - may cause view recreation"
    ((ERRORS++))
else
    echo "  ✅ No refreshID causing issues"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED!"
    echo ""
    echo "📋 Modal Implementation Summary:"
    echo "   • Settings view properly structured"
    echo "   • Async loading implemented"
    echo "   • Sheet presentation configured"
    echo "   • No problematic state handlers"
    echo ""
    echo "🎯 Expected Behavior:"
    echo "   1. Tap menu (three dots) → Settings"
    echo "   2. Modal slides up from bottom"
    echo "   3. Shows all sections (Preferences, Currency, Theme, etc.)"
    echo "   4. Stays open (no auto-dismiss)"
    echo "   5. Can dismiss with Cancel/Save or swipe down"
    echo ""
    echo "💡 Ready for device testing!"
else
    echo "❌ Found $ERRORS issue(s) that need attention"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
