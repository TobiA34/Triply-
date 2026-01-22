//
//  SmartThemeGenerator.swift
//  Itinero
//
//  Smart theme generator that creates harmonious color palettes
//

import SwiftUI

@MainActor
class SmartThemeGenerator: ObservableObject {
    static let shared = SmartThemeGenerator()
    
    private init() {}
    
    // Generate a theme based on a seed color
    func generateTheme(from seedColor: Color, name: String? = nil) -> CustomTheme.Palette {
        let uiColor = UIColor(seedColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Generate harmonious colors
        let accent = seedColor
        
        // Create a light, harmonious background
        let background = Color(
            red: min(1.0, r * 0.15 + 0.95),
            green: min(1.0, g * 0.15 + 0.95),
            blue: min(1.0, b * 0.15 + 0.95)
        )
        
        // Ensure good contrast for text
        let text = Color(
            red: max(0.1, 1.0 - r * 0.3),
            green: max(0.1, 1.0 - g * 0.3),
            blue: max(0.1, 1.0 - b * 0.3)
        )
        
        // Secondary text with less contrast
        let secondaryText = Color(
            red: max(0.2, 1.0 - r * 0.2),
            green: max(0.2, 1.0 - g * 0.2),
            blue: max(0.2, 1.0 - b * 0.2)
        ).opacity(0.7)
        
        return CustomTheme.Palette(
            accent: accent,
            background: background,
            text: text,
            secondaryText: secondaryText
        )
    }
    
    // Generate theme from a photo/image (extract dominant colors)
    func generateThemeFromImage(_ image: UIImage, name: String? = nil) -> CustomTheme.Palette? {
        guard let dominantColor = extractDominantColor(from: image) else {
            return nil
        }
        
        let themeName = name ?? "Photo Theme"
        return generateTheme(from: Color(uiColor: dominantColor), name: themeName)
    }
    
    // Extract dominant color from image
    private func extractDominantColor(from image: UIImage) -> UIColor? {
        guard image.cgImage != nil else { return nil }
        
        // Resize image for faster processing
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.interpolationQuality = .low
        image.draw(in: CGRect(origin: .zero, size: size))
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let resizedCGImage = resizedImage.cgImage else {
            return nil
        }
        
        // Get pixel data
        let width = resizedCGImage.width
        let height = resizedCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Calculate average color
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        var pixelCount = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * bytesPerPixel
                let red = CGFloat(pixelData[index]) / 255.0
                let green = CGFloat(pixelData[index + 1]) / 255.0
                let blue = CGFloat(pixelData[index + 2]) / 255.0
                let alpha = CGFloat(pixelData[index + 3]) / 255.0
                
                // Skip very transparent pixels
                if alpha > 0.5 {
                    r += red
                    g += green
                    b += blue
                    a += alpha
                    pixelCount += 1
                }
            }
        }
        
        guard pixelCount > 0 else { return nil }
        
        r /= CGFloat(pixelCount)
        g /= CGFloat(pixelCount)
        b /= CGFloat(pixelCount)
        a /= CGFloat(pixelCount)
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    // Generate theme suggestions based on popular color schemes
    func generateThemeSuggestions() -> [(String, CustomTheme.Palette)] {
        return [
            ("Ocean Breeze", generateTheme(from: .teal, name: "Ocean Breeze")),
            ("Sunset Glow", generateTheme(from: .orange, name: "Sunset Glow")),
            ("Forest Green", generateTheme(from: .green, name: "Forest Green")),
            ("Lavender Dream", generateTheme(from: .purple, name: "Lavender Dream")),
            ("Rose Gold", generateTheme(from: Color(red: 0.85, green: 0.65, blue: 0.65), name: "Rose Gold")),
            ("Sky Blue", generateTheme(from: .blue, name: "Sky Blue")),
            ("Coral Reef", generateTheme(from: Color(red: 1.0, green: 0.5, blue: 0.5), name: "Coral Reef")),
            ("Golden Hour", generateTheme(from: Color(red: 1.0, green: 0.84, blue: 0.0), name: "Golden Hour"))
        ]
    }
    
    // Generate theme from trip cover image
    func generateThemeFromTrip(_ trip: TripModel) -> CustomTheme.Palette? {
        // TripModel doesn't have coverImage property, use category-based color
        return generateThemeFromCategory(trip.category)
    }
    
    // Generate theme from trip category
    func generateThemeFromCategory(_ category: String) -> CustomTheme.Palette {
        let color: Color
        switch category.lowercased() {
        case "adventure":
            color = .orange
        case "business":
            color = .blue
        case "relaxation":
            color = .teal
        case "family":
            color = .green
        case "romantic":
            color = .pink
        case "solo":
            color = .purple
        case "group":
            color = .indigo
        default:
            color = .blue
        }
        
        return generateTheme(from: color, name: "\(category) Theme")
    }
}
