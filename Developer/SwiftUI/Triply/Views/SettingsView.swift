//
//  SettingsView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedCurrency: Currency
    @State private var selectedTheme: AppTheme
    @State private var selectedLanguage: SupportedLanguage
    @State private var refreshID = UUID()
    
    init() {
        // Initialize with current settings - access on main thread
        // Use default values first, then update in onAppear to avoid crashes
        _selectedCurrency = State(initialValue: Currency.currency(for: "USD"))
        _selectedTheme = State(initialValue: .system)
        _selectedLanguage = State(initialValue: .english)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                currencySection
                themeSection
                themeCustomizationSection
                themeDefaultsSection
                themeDefaultsInlineSection
                languageSection
                previewSection
                aboutSection
                proSection
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        resetSelections()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        print("🔵 Save button tapped")
                        print("   Selected currency: \(selectedCurrency.code)")
                        print("   Current currency: \(settingsManager.currentCurrency.code)")
                        saveSettings()
                        // Small delay to ensure save completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
            .onChange(of: selectedCurrency) { oldValue, newValue in
                print("🟢 Currency changed in SettingsView: \(oldValue.code) → \(newValue.code)")
            }
            .onChange(of: localizationManager.currentLanguage) { oldValue, newValue in
                // Update selected language when manager changes
                selectedLanguage = newValue
                refreshID = UUID()
            }
            .id(refreshID) // Force refresh on language change
        }
    }
    
    private var themeDefaultsInlineSection: some View {
        Section {
            if selectedTheme != .custom {
                Picker("Default Palette", selection: Binding(
                    get: { themeManager.defaultPalette },
                    set: { newValue in
                        themeManager.setDefaultPalette(newValue)
                    }
                )) {
                    ForEach(DefaultPalette.allCases) { palette in
                        HStack {
                            Text(palette.title)
                            Spacer()
                            palettePreview(palette)
                        }
                        .tag(palette)
                    }
                }
                ColorPicker("Accent", selection: Binding(
                    get: { themeManager.customAccentColor },
                    set: { newColor in
                        themeManager.setAccentColor(newColor)
                    }
                ), supportsOpacity: true)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom theme is active.")
                    NavigationLink {
                        ThemeLibraryView()
                    } label: {
                        Label("Manage Custom Themes", systemImage: "paintpalette.fill")
                    }
                }
            }
        } header: {
            Text("Theme Defaults")
        } footer: {
            Text("Choose the base palette and accent used across the app when not using a custom theme.")
        }
    }
    
    private func palettePreview(_ palette: DefaultPalette) -> some View {
        let light = palette.palette(for: .light)
        return HStack(spacing: 4) {
            Circle().fill(light.accent).frame(width: 8, height: 8)
            Circle().fill(light.background).frame(width: 8, height: 8).overlay(Circle().stroke(Color.gray.opacity(0.2)))
            Circle().fill(light.text).frame(width: 8, height: 8)
            Circle().fill(light.secondaryText).frame(width: 8, height: 8)
        }
    }
    
    private var preferencesSection: some View {
        Section {
            preferenceRow(icon: "dollarsign.circle.fill", color: .green, title: "settings.currency".localized)
            preferenceRow(icon: "paintbrush.fill", color: .blue, title: "settings.theme".localized)
            preferenceRow(icon: "globe", color: .purple, title: "settings.language".localized)
        } header: {
            Text("settings.preferences".localized)
        } footer: {
            Text("settings.preferences.description".localized)
        }
    }
    
    private func preferenceRow(icon: String, color: Color, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
    
    private var currencySection: some View {
        Section {
            NavigationLink {
                CurrencySelectionView(selectedCurrency: $selectedCurrency)
                    .onDisappear {
                        // Force update when returning from selection
                        print("🟡 Currency selection view dismissed")
                        print("   Selected currency: \(selectedCurrency.code)")
                    }
            } label: {
                HStack {
                    Text("Currency")
                    Spacer()
                    HStack(spacing: 8) {
                        Text(selectedCurrency.symbol)
                            .font(.headline)
                        Text(selectedCurrency.name)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: CurrencyConverterView()) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundColor(.orange)
                    Text("Currency Converter")
                }
            }
        } header: {
            Text("Select Currency")
        }
    }
    
    private func currencyRow(currency: Currency) -> some View {
        HStack {
            Text(currency.symbol)
                .font(.title3)
                .frame(width: 40, alignment: .leading)
            Text(currency.name)
            Spacer()
            Text(currency.code)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var themeSection: some View {
        Section {
            Picker("Theme", selection: $selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    themeRow(theme: theme)
                        .tag(theme)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("settings.appTheme".localized)
        } footer: {
            Text("settings.theme.description".localized)
        }
    }
    
    private var themeCustomizationSection: some View {
        Section {
            NavigationLink {
                ThemeLibraryView()
            } label: {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(.blue)
                    Text("Customize Theme")
                }
            }
        }
    }
    
    private var themeDefaultsSection: some View {
        Section {
            NavigationLink {
                ThemeDefaultsView()
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.purple)
                    Text("Theme Defaults")
                }
            }
        } header: {
            Text("Default Theme")
        } footer: {
            Text("Choose a base palette and default accent used across the app, unless a custom theme is active.")
        }
    }
    
    private func themeRow(theme: AppTheme) -> some View {
        HStack {
            Image(systemName: themeIcon(for: theme))
            Text(theme.rawValue)
        }
    }
    
    private func themeIcon(for theme: AppTheme) -> String {
        switch theme {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        case .custom: return "paintpalette.fill"
        }
    }
    
    private var languageSection: some View {
        Section {
            NavigationLink {
                LanguageSelectionView(selectedLanguage: $selectedLanguage)
                    .onDisappear {
                        // Force update when returning from selection
                        print("🟡 Language selection view dismissed")
                        print("   Selected language: \(selectedLanguage.rawValue)")
                    }
            } label: {
                HStack {
                    Text("settings.language".localized)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(selectedLanguage.enhanced.flag)
                            .font(.title3)
                        Text(selectedLanguage.nativeName)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("settings.appLanguage".localized)
        } footer: {
            Text("settings.language.description".localized)
        }
    }
    
    private var previewSection: some View {
        Section {
            HStack {
                Text("settings.currentSelection".localized)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Text(selectedCurrency.symbol)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(selectedCurrency.code)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("settings.example".localized)
                    .foregroundColor(.secondary)
                Spacer()
                // Use selectedCurrency for preview, not settingsManager (which hasn't updated yet)
                Text("\(selectedCurrency.symbol)\(String(format: "%.2f", 1000.0))")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        } header: {
            Text("settings.preview".localized)
        }
    }
    
    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("settings.aboutTriply".localized)
                        .font(.headline)
                }
                
                Text("app.version".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("app.description".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text("settings.appInformation".localized)
        }
    }
    
    private var proSection: some View {
        Section {
            HStack {
                Image(systemName: IAPManager.shared.isPro ? "crown.fill" : "crown")
                    .foregroundColor(.yellow)
                Text(IAPManager.shared.isPro ? "Pro Unlocked" : "Upgrade to Pro")
                Spacer()
                if IAPManager.shared.isPro {
                    Text("Active").foregroundColor(.green)
                }
            }
            if !IAPManager.shared.isPro {
                NavigationLink {
                    PaywallView()
                } label: {
                    Label("Unlock Pro", systemImage: "lock.open.fill")
                }
                Button {
                    Task { await IAPManager.shared.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise.circle")
                }
            }
        } header: {
            Text("Pro")
        } footer: {
            if let msg = IAPManager.shared.lastInfoMessage {
                Text(msg).font(.footnote)
            } else if let err = IAPManager.shared.lastErrorMessage {
                Text(err).font(.footnote).foregroundColor(.red)
            } else {
                EmptyView()
            }
        }
    }
    
    private func resetSelections() {
        selectedCurrency = settingsManager.currentCurrency
        selectedTheme = themeManager.currentTheme
        selectedLanguage = localizationManager.currentLanguage
    }
    
    private func saveSettings() {
        print("💾 Saving settings...")
        print("   Selected currency: \(selectedCurrency.code) (\(selectedCurrency.symbol))")
        print("   Current manager currency: \(settingsManager.currentCurrency.code)")
        
        // Update currency in database FIRST
        settingsManager.updateCurrency(selectedCurrency, in: modelContext)
        
        // Force immediate update to published property
        settingsManager.currentCurrency = selectedCurrency
        
        // Update theme and language
        themeManager.setTheme(selectedTheme)
        
        // Update language - this will trigger UI refresh
        if localizationManager.currentLanguage != selectedLanguage {
            localizationManager.setLanguage(selectedLanguage)
            // Force immediate UI update
            DispatchQueue.main.async {
                // Trigger view refresh by updating a published property
                self.localizationManager.objectWillChange.send()
            }
        }
        
        // Save context to ensure persistence
        do {
            try modelContext.save()
            print("✅ Context saved")
        } catch {
            print("❌ Failed to save context: \(error)")
        }
        
        // Verify after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.settingsManager.loadSettings(from: self.modelContext)
            print("✅ Settings saved and reloaded - Final currency: \(self.settingsManager.currentCurrency.code)")
        }
    }
    
    private func loadSettings() {
        settingsManager.loadSettings(from: modelContext)
        themeManager.loadTheme()
        localizationManager.loadLanguage()
        
        // Update state with loaded settings
        selectedCurrency = settingsManager.currentCurrency
        selectedTheme = themeManager.currentTheme
        selectedLanguage = localizationManager.currentLanguage
        
        print("🔵 Loaded settings - Currency: \(selectedCurrency.code)")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}

