//
//  CustomTheme.swift
//  Triply
//
//  Created on 2025
//

import Foundation
import SwiftUI
import SwiftData

enum UserTier: String, Codable, CaseIterable {
    case free
    case plus
    case pro
    
    var maxCustomThemes: Int? {
        switch self {
        case .free: return 1
        case .plus: return 3
        case .pro: return nil // unlimited
        }
    }
}

@Model
final class CustomTheme {
    @Attribute(.unique) var id: UUID
    var name: String
    
    // Store colors as hex strings for persistence portability
    var accentHex: String
    var backgroundHex: String
    var textHex: String
    var secondaryTextHex: String
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        accentHex: String,
        backgroundHex: String,
        textHex: String,
        secondaryTextHex: String
    ) {
        self.id = id
        self.name = name
        self.accentHex = accentHex
        self.backgroundHex = backgroundHex
        self.textHex = textHex
        self.secondaryTextHex = secondaryTextHex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension CustomTheme {
    struct Palette: Equatable {
        let accent: Color
        let background: Color
        let text: Color
        let secondaryText: Color
        
        // Equatable conformance by comparing hex values
        static func == (lhs: Palette, rhs: Palette) -> Bool {
            return lhs.accent.hexRGBA == rhs.accent.hexRGBA &&
                   lhs.background.hexRGBA == rhs.background.hexRGBA &&
                   lhs.text.hexRGBA == rhs.text.hexRGBA &&
                   lhs.secondaryText.hexRGBA == rhs.secondaryText.hexRGBA
        }
    }
    
    var palette: Palette {
        Palette(
            accent: Color(hex: accentHex) ?? .blue,
            background: Color(hex: backgroundHex) ?? .white,
            text: Color(hex: textHex) ?? .primary,
            secondaryText: Color(hex: secondaryTextHex) ?? .secondary
        )
    }
}

extension Color {
    init?(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if string.hasPrefix("#") { string.removeFirst() }
        guard string.count == 6 || string.count == 8 else { return nil }
        
        var rgba: UInt64 = 0
        guard Scanner(string: string).scanHexInt64(&rgba) else { return nil }
        
        let hasAlpha = string.count == 8
        let r = Double((rgba & 0xFF000000) >> 24) / 255.0
        let g = Double((rgba & 0x00FF0000) >> 16) / 255.0
        let b = Double((rgba & 0x0000FF00) >> 8) / 255.0
        let a = hasAlpha ? Double(rgba & 0x000000FF) / 255.0 : 1.0
        
        self = Color(red: r, green: g, blue: b, opacity: a)
    }
    
    var hexRGBA: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rr = Int(round(r * 255))
        let gg = Int(round(g * 255))
        let bb = Int(round(b * 255))
        // For folder colors, we only need RGB (no alpha), matching the format used
        return String(format: "#%02X%02X%02X", rr, gg, bb)
    }
}



