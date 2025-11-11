//
//  ThemeLibraryView.swift
//  Triply
//
//  Created on 2025
//

import SwiftUI

struct ThemeLibraryView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingCreate = false
    @State private var editingTheme: CustomTheme?
    @State private var showingPaywall = false
    
    var body: some View {
        List {
            Section(header: Text("Active Theme")) {
                Picker("Appearance", selection: $themeManager.currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                
                if themeManager.currentTheme == .custom,
                   !themeManager.customThemes.isEmpty {
                    Picker("Custom", selection: Binding(
                        get: { themeManager.activeCustomThemeID },
                        set: { themeManager.selectCustomTheme(id: $0) }
                    )) {
                        ForEach(themeManager.customThemes, id: \.id) { theme in
                            Text(theme.name).tag(Optional(theme.id))
                        }
                    }
                }
            }
            
            Section(header: Text("My Themes"),
                    footer: tierFooter) {
                ForEach(themeManager.customThemes, id: \.id) { theme in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(theme.name)
                                .font(.headline)
                            HStack {
                                Circle().fill(Color(hex: theme.accentHex) ?? .blue).frame(width: 16, height: 16)
                                Circle().fill(Color(hex: theme.backgroundHex) ?? .white).frame(width: 16, height: 16)
                                Circle().fill(Color(hex: theme.textHex) ?? .primary).frame(width: 16, height: 16)
                                Circle().fill(Color(hex: theme.secondaryTextHex) ?? .secondary).frame(width: 16, height: 16)
                            }
                        }
                        Spacer()
                        if themeManager.activeCustomThemeID == theme.id, themeManager.currentTheme == .custom {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        themeManager.selectCustomTheme(id: theme.id)
                        themeManager.setTheme(.custom)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            themeManager.deleteTheme(id: theme.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingTheme = theme
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
                
                if canCreateTheme {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("Create Theme", systemImage: "plus.circle.fill")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill").foregroundColor(.orange)
                            Text("Upgrade to unlock unlimited themes")
                        }
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Upgrade to Pro", systemImage: "crown.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Section(header: Text("Accent Color")) {
                ColorPicker("Accent", selection: Binding(
                    get: { themeManager.customAccentColor },
                    set: { themeManager.setAccentColor($0) }
                ), supportsOpacity: true)
            }
        }
        .navigationTitle("Themes")
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                ThemeCreatorView()
            }
        }
        .sheet(item: $editingTheme, content: { theme in
            NavigationStack {
                ThemeCreatorView(editingTheme: theme)
            }
        })
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .onAppear {
            themeManager.reloadCustomThemes()
        }
    }
    
    private var canCreateTheme: Bool {
        if let max = themeManager.userTier.maxCustomThemes {
            return themeManager.customThemes.count < max
        }
        return true
    }
    
    private var tierFooter: some View {
        let tier = themeManager.userTier
        return Text(limitText(for: tier))
            .font(.footnote)
            .foregroundColor(.secondary)
    }
    
    private func limitText(for tier: UserTier) -> String {
        switch tier {
        case .free: return "Free: up to 1 custom theme"
        case .plus: return "Plus: up to 3 custom themes"
        case .pro: return "Pro: unlimited custom themes"
        }
    }
}

#Preview {
    NavigationStack {
        ThemeLibraryView()
            .modelContainer(for: [CustomTheme.self], inMemory: true)
    }
}


