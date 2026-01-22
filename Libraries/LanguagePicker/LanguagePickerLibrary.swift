//
//  LanguagePickerLibrary.swift
//  Itinero
//
//  A comprehensive language picker library with search, flags, and grouping
//

import SwiftUI
import Foundation

// MARK: - Enhanced Language Model
public struct EnhancedLanguage: Identifiable, Hashable, Codable {
    public let id: String
    public let code: String
    public let name: String
    public let nativeName: String
    public let flag: String // Emoji flag
    public let region: LanguageRegion
    public let isPopular: Bool
    
    public init(code: String, name: String, nativeName: String, flag: String, region: LanguageRegion, isPopular: Bool = false) {
        self.id = code
        self.code = code
        self.name = name
        self.nativeName = nativeName
        self.flag = flag
        self.region = region
        self.isPopular = isPopular
    }
}

// MARK: - Language Region
public enum LanguageRegion: String, CaseIterable, Codable {
    case europe = "Europe"
    case americas = "Americas"
    case asia = "Asia"
    case africa = "Africa"
    case middleEast = "Middle East"
    case oceania = "Oceania"
    case other = "Other"
    
    public var icon: String {
        switch self {
        case .europe: return "🇪🇺"
        case .americas: return "🌎"
        case .asia: return "🌏"
        case .africa: return "🌍"
        case .middleEast: return "🕌"
        case .oceania: return "🌊"
        case .other: return "🌐"
        }
    }
}

// MARK: - Language Database
public class LanguageDatabase {
    public static let shared = LanguageDatabase()
    
    public let allLanguages: [EnhancedLanguage]
    public let popularLanguages: [EnhancedLanguage]
    
    private init() {
        allLanguages = [
            // Popular Languages
            EnhancedLanguage(code: "en", name: "English", nativeName: "English", flag: "🇬🇧", region: .europe, isPopular: true),
            EnhancedLanguage(code: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸", region: .europe, isPopular: true),
            EnhancedLanguage(code: "fr", name: "French", nativeName: "Français", flag: "🇫🇷", region: .europe, isPopular: true),
            EnhancedLanguage(code: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪", region: .europe, isPopular: true),
            EnhancedLanguage(code: "zh-Hans", name: "Chinese (Simplified)", nativeName: "简体中文", flag: "🇨🇳", region: .asia, isPopular: true),
            EnhancedLanguage(code: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵", region: .asia, isPopular: true),
            EnhancedLanguage(code: "ko", name: "Korean", nativeName: "한국어", flag: "🇰🇷", region: .asia, isPopular: true),
            EnhancedLanguage(code: "pt", name: "Portuguese", nativeName: "Português", flag: "🇵🇹", region: .europe, isPopular: true),
            EnhancedLanguage(code: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹", region: .europe, isPopular: true),
            EnhancedLanguage(code: "ru", name: "Russian", nativeName: "Русский", flag: "🇷🇺", region: .europe, isPopular: true),
            
            // Europe
            EnhancedLanguage(code: "nl", name: "Dutch", nativeName: "Nederlands", flag: "🇳🇱", region: .europe),
            EnhancedLanguage(code: "pl", name: "Polish", nativeName: "Polski", flag: "🇵🇱", region: .europe),
            EnhancedLanguage(code: "sv", name: "Swedish", nativeName: "Svenska", flag: "🇸🇪", region: .europe),
            EnhancedLanguage(code: "no", name: "Norwegian", nativeName: "Norsk", flag: "🇳🇴", region: .europe),
            EnhancedLanguage(code: "da", name: "Danish", nativeName: "Dansk", flag: "🇩🇰", region: .europe),
            EnhancedLanguage(code: "fi", name: "Finnish", nativeName: "Suomi", flag: "🇫🇮", region: .europe),
            EnhancedLanguage(code: "cs", name: "Czech", nativeName: "Čeština", flag: "🇨🇿", region: .europe),
            EnhancedLanguage(code: "hu", name: "Hungarian", nativeName: "Magyar", flag: "🇭🇺", region: .europe),
            EnhancedLanguage(code: "ro", name: "Romanian", nativeName: "Română", flag: "🇷🇴", region: .europe),
            EnhancedLanguage(code: "el", name: "Greek", nativeName: "Ελληνικά", flag: "🇬🇷", region: .europe),
            EnhancedLanguage(code: "tr", name: "Turkish", nativeName: "Türkçe", flag: "🇹🇷", region: .europe),
            
            // Americas
            EnhancedLanguage(code: "pt-BR", name: "Portuguese (Brazil)", nativeName: "Português (Brasil)", flag: "🇧🇷", region: .americas),
            EnhancedLanguage(code: "es-MX", name: "Spanish (Mexico)", nativeName: "Español (México)", flag: "🇲🇽", region: .americas),
            EnhancedLanguage(code: "es-AR", name: "Spanish (Argentina)", nativeName: "Español (Argentina)", flag: "🇦🇷", region: .americas),
            EnhancedLanguage(code: "fr-CA", name: "French (Canada)", nativeName: "Français (Canada)", flag: "🇨🇦", region: .americas),
            
            // Asia
            EnhancedLanguage(code: "zh-Hant", name: "Chinese (Traditional)", nativeName: "繁體中文", flag: "🇹🇼", region: .asia),
            EnhancedLanguage(code: "hi", name: "Hindi", nativeName: "हिन्दी", flag: "🇮🇳", region: .asia),
            EnhancedLanguage(code: "th", name: "Thai", nativeName: "ไทย", flag: "🇹🇭", region: .asia),
            EnhancedLanguage(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳", region: .asia),
            EnhancedLanguage(code: "id", name: "Indonesian", nativeName: "Bahasa Indonesia", flag: "🇮🇩", region: .asia),
            EnhancedLanguage(code: "ms", name: "Malay", nativeName: "Bahasa Melayu", flag: "🇲🇾", region: .asia),
            EnhancedLanguage(code: "tl", name: "Filipino", nativeName: "Filipino", flag: "🇵🇭", region: .asia),
            EnhancedLanguage(code: "ar", name: "Arabic", nativeName: "العربية", flag: "🇸🇦", region: .middleEast),
            
            // Middle East
            EnhancedLanguage(code: "he", name: "Hebrew", nativeName: "עברית", flag: "🇮🇱", region: .middleEast),
            EnhancedLanguage(code: "fa", name: "Persian", nativeName: "فارسی", flag: "🇮🇷", region: .middleEast),
            
            // Oceania
            EnhancedLanguage(code: "en-AU", name: "English (Australia)", nativeName: "English (Australia)", flag: "🇦🇺", region: .oceania),
            EnhancedLanguage(code: "en-NZ", name: "English (New Zealand)", nativeName: "English (New Zealand)", flag: "🇳🇿", region: .oceania),
        ]
        
        popularLanguages = allLanguages.filter { $0.isPopular }
    }
    
    public func language(for code: String) -> EnhancedLanguage? {
        // Try exact match first
        if let exact = allLanguages.first(where: { $0.code == code }) {
            return exact
        }
        // Try base language code (e.g., "pt" for "pt-BR")
        let baseCode = code.components(separatedBy: "-").first ?? code
        return allLanguages.first { $0.code == baseCode || $0.code.components(separatedBy: "-").first == baseCode }
    }
    
    public func search(query: String) -> [EnhancedLanguage] {
        let lowercased = query.lowercased()
        return allLanguages.filter { language in
            language.code.lowercased().contains(lowercased) ||
            language.name.lowercased().contains(lowercased) ||
            language.nativeName.lowercased().contains(lowercased)
        }
    }
    
    public func languages(by region: LanguageRegion) -> [EnhancedLanguage] {
        allLanguages.filter { $0.region == region }
    }
}

// MARK: - Language Picker View
public struct LanguagePickerView: View {
    @Binding var selectedLanguage: EnhancedLanguage
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var selectedRegion: LanguageRegion? = nil
    @State private var showPopularOnly = false
    
    private let database = LanguageDatabase.shared
    
    public init(selectedLanguage: Binding<EnhancedLanguage>) {
        self._selectedLanguage = selectedLanguage
    }
    
    private var filteredLanguages: [EnhancedLanguage] {
        var languages: [EnhancedLanguage]
        
        if !searchText.isEmpty {
            languages = database.search(query: searchText)
        } else if let region = selectedRegion {
            languages = database.languages(by: region)
        } else if showPopularOnly {
            languages = database.popularLanguages
        } else {
            languages = database.allLanguages
        }
        
        return languages.sorted { $0.name < $1.name }
    }
    
    private var groupedLanguages: [LanguageRegion: [EnhancedLanguage]] {
        Dictionary(grouping: filteredLanguages) { $0.region }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filter Pills
                filterPills
                
                // Language List
                if filteredLanguages.isEmpty {
                    emptyState
                } else {
                    languageList
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search language...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                LanguageFilterPill(
                    title: "Popular",
                    icon: "star.fill",
                    isSelected: showPopularOnly && selectedRegion == nil,
                    action: {
                        showPopularOnly.toggle()
                        selectedRegion = nil
                    }
                )
                
                ForEach(LanguageRegion.allCases, id: \.self) { region in
                    LanguageFilterPill(
                        title: region.rawValue,
                        icon: region.icon,
                        isSelected: selectedRegion == region && !showPopularOnly,
                        action: {
                            if selectedRegion == region {
                                selectedRegion = nil
                            } else {
                                selectedRegion = region
                                showPopularOnly = false
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var languageList: some View {
        List {
            if showPopularOnly && selectedRegion == nil && searchText.isEmpty {
                Section {
                    ForEach(database.popularLanguages) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedLanguage.code == language.code
                        ) {
                            selectedLanguage = language
                        }
                    }
                } header: {
                    Text("Popular Languages")
                }
            } else {
                ForEach(LanguageRegion.allCases, id: \.self) { region in
                    if let languages = groupedLanguages[region], !languages.isEmpty {
                        Section {
                            ForEach(languages) { language in
                                LanguageRow(
                                    language: language,
                                    isSelected: selectedLanguage.code == language.code
                                ) {
                                    selectedLanguage = language
                                }
                            }
                        } header: {
                            HStack {
                                Text(region.icon)
                                Text(region.rawValue)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No languages found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: EnhancedLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 28))
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                
                // Language Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(language.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Code
                Text(language.code.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill
struct LanguageFilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if icon != title && !icon.contains("🇪🇺") && !icon.contains("🌎") && !icon.contains("🌏") && !icon.contains("🌍") && !icon.contains("🕌") && !icon.contains("🌊") && !icon.contains("🌐") {
                    Image(systemName: icon)
                        .font(.caption)
                } else {
                    Text(icon)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview
#Preview {
    LanguagePickerView(selectedLanguage: .constant(LanguageDatabase.shared.allLanguages.first!))
}

