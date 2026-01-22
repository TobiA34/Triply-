#!/usr/bin/env swift
// Quick test to verify Settings modal structure

import Foundation

print("🔍 Testing Settings Modal Implementation...")
print("")

// Check if key files exist
let files = [
    "Views/SettingsView.swift",
    "Views/TripListView.swift"
]

var allGood = true

for file in files {
    let filePath = "/Users/tobiadegoroye/Developer/SwiftUI/Triply/\(file)"
    if FileManager.default.fileExists(atPath: filePath) {
        print("✅ \(file) exists")
        
        // Check for key components
        if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
            if file.contains("SettingsView") {
                let checks = [
                    ("@Environment(\.dismiss)", "Dismiss environment"),
                    ("@State private var selectedCurrency", "Currency state"),
                    ("@State private var selectedTheme", "Theme state"),
                    ("@State private var selectedLanguage", "Language state"),
                    (".task {", "Async task loading"),
                    ("loadSettingsAsync()", "Async settings load"),
                    ("Form {", "Form structure"),
                    ("preferencesSection", "Preferences section"),
                    ("currencySection", "Currency section"),
                    ("themeSection", "Theme section"),
                    ("languageSection", "Language section")
                ]
                
                for (pattern, description) in checks {
                    if content.contains(pattern) {
                        print("   ✅ \(description)")
                    } else {
                        print("   ❌ Missing: \(description)")
                        allGood = false
                    }
                }
            } else if file.contains("TripListView") {
                let checks = [
                    ("@State private var showingSettings", "Settings state"),
                    (".sheet(isPresented: $showingSettings)", "Sheet presentation"),
                    ("NavigationStack", "Navigation wrapper"),
                    ("SettingsView()", "Settings view instantiation"),
                    (".presentationDetents", "Presentation detents"),
                    (".presentationDragIndicator", "Drag indicator")
                ]
                
                for (pattern, description) in checks {
                    if content.contains(pattern) {
                        print("   ✅ \(description)")
                    } else {
                        print("   ❌ Missing: \(description)")
                        allGood = false
                    }
                }
            }
        }
    } else {
        print("❌ \(file) NOT FOUND")
        allGood = false
    }
    print("")
}

print("")
if allGood {
    print("✅ All checks passed! Settings modal structure looks good.")
    print("")
    print("📋 Expected Behavior:")
    print("   • Modal opens when Settings button is tapped")
    print("   • Shows all sections (Preferences, Currency, Theme, Language, etc.)")
    print("   • Stays open and doesn't auto-dismiss")
    print("   • Can be dismissed with Cancel or Save button")
    print("   • Can be swiped down to dismiss")
} else {
    print("❌ Some issues found. Please review the code.")
}

print("")
print("💡 To test on device:")
print("   1. Build and run in Xcode")
print("   2. Tap the menu (three dots) in Trip List")
print("   3. Tap 'Settings'")
print("   4. Verify modal opens and stays open")
print("   5. Check all sections are visible")
print("   6. Test Cancel and Save buttons")
