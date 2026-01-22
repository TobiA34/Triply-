//
//  SocialMediaManager.swift
//  Itinero
//
//  Social media integration for 1-tap save from Instagram/TikTok
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
class SocialMediaManager: ObservableObject {
    static let shared = SocialMediaManager()
    
    @Published var isProcessing = false
    @Published var lastExtractedLocation: ExtractedLocation?
    
    private init() {}
    
    // MARK: - Extract Location from URL
    func extractLocation(from urlString: String) async -> ExtractedLocation? {
        isProcessing = true
        defer { isProcessing = false }
        
        // Parse Instagram URLs
        if urlString.contains("instagram.com") {
            return await extractFromInstagram(url: urlString)
        }
        
        // Parse TikTok URLs
        if urlString.contains("tiktok.com") {
            return await extractFromTikTok(url: urlString)
        }
        
        // Try to extract location from any URL
        return await extractFromGenericURL(url: urlString)
    }
    
    // MARK: - Instagram Extraction
    private func extractFromInstagram(url: String) async -> ExtractedLocation? {
        // Fetch and scrape data from the actual Instagram URL
        let scrapedData = await scrapeURL(url)
        
        // Try to extract location name from URL or clipboard
        var locationName: String?
        var address: String?
        
        // First, try scraped data
        if let scrapedTitle = scrapedData.title, !scrapedTitle.isEmpty {
            locationName = extractLocationName(from: scrapedTitle)
        }
        
        // Try clipboard as fallback
        if locationName == nil {
            if let clipboardText = UIPasteboard.general.string,
               !clipboardText.isEmpty {
                locationName = extractLocationName(from: clipboardText)
                address = extractAddress(from: clipboardText)
            }
        }
        
        // If not found, try URL itself
        if locationName == nil {
            locationName = extractLocationName(from: url)
        }
        
        // If still no location, try to parse Instagram post ID and use a generic name
        if locationName == nil {
            if let postId = extractPostId(from: url) {
                locationName = "Instagram Post \(postId)"
            } else {
                locationName = "Instagram Location"
            }
        }
        
        // Use scraped title/description, fallback to clipboard extraction
        let videoTitle = scrapedData.title ?? extractVideoInfo(from: url).title
        let description = scrapedData.description ?? extractVideoInfo(from: url).description
        
        return ExtractedLocation(
            name: locationName ?? "Unknown Location",
            address: address ?? scrapedData.location,
            latitude: scrapedData.latitude,
            longitude: scrapedData.longitude,
            sourceURL: url,
            sourceType: .instagram,
            imageURL: scrapedData.imageURL,
            videoTitle: videoTitle,
            description: description
        )
    }
    
    // MARK: - TikTok Extraction
    private func extractFromTikTok(url: String) async -> ExtractedLocation? {
        // Fetch and scrape data from the actual TikTok URL
        let scrapedData = await scrapeURL(url)
        
        var locationName: String?
        var address: String?
        
        // First, try scraped data
        if let scrapedTitle = scrapedData.title, !scrapedTitle.isEmpty {
            locationName = extractLocationName(from: scrapedTitle)
        }
        
        // Try clipboard as fallback
        if locationName == nil {
            if let clipboardText = UIPasteboard.general.string,
               !clipboardText.isEmpty {
                locationName = extractLocationName(from: clipboardText)
                address = extractAddress(from: clipboardText)
            }
        }
        
        // If not found, try URL
        if locationName == nil {
            locationName = extractLocationName(from: url)
        }
        
        // Default name if nothing found
        if locationName == nil {
            locationName = "TikTok Location"
        }
        
        // Use scraped title/description, fallback to clipboard extraction
        let videoTitle = scrapedData.title ?? extractVideoInfo(from: url).title
        let description = scrapedData.description ?? extractVideoInfo(from: url).description
        
        return ExtractedLocation(
            name: locationName ?? "Unknown Location",
            address: address ?? scrapedData.location,
            latitude: scrapedData.latitude,
            longitude: scrapedData.longitude,
            sourceURL: url,
            sourceType: .tiktok,
            imageURL: scrapedData.imageURL,
            videoTitle: videoTitle,
            description: description
        )
    }
    
    // MARK: - Generic URL Extraction
    private func extractFromGenericURL(url: String) async -> ExtractedLocation? {
        // Try to extract location from clipboard or shared text
        if let clipboardText = UIPasteboard.general.string,
           let locationName = extractLocationName(from: clipboardText) {
            let (videoTitle, description) = extractVideoInfo(from: url)
            
            return ExtractedLocation(
                name: locationName,
                address: nil,
                latitude: nil,
                longitude: nil,
                sourceURL: url,
                sourceType: .generic,
                imageURL: nil,
                videoTitle: videoTitle,
                description: description
            )
        }
        
        return nil
    }
    
    // MARK: - Location Name Extraction
    private func extractLocationName(from text: String) -> String? {
        // Simple pattern matching for location names
        // In production, use NLP or location detection APIs
        
        let patterns = [
            #"📍\s*([A-Za-z0-9\s,]+)"#,  // Instagram/TikTok location format with emoji
            #"at\s+([A-Za-z0-9\s,]+)"#,  // "at Location Name"
            #"in\s+([A-Za-z0-9\s,]+)"#,  // "in Location Name"
            #"Location:\s*([A-Za-z0-9\s,]+)"#,  // "Location: Name"
            #"📍\s*([^📍\n]+)"#,  // Any text after location emoji
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                var locationName = String(text[range]).trimmingCharacters(in: .whitespaces)
                // Remove common trailing words
                locationName = locationName.replacingOccurrences(of: #"\s*,\s*$"#, with: "", options: .regularExpression)
                if !locationName.isEmpty && locationName.count > 2 {
                    return locationName
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Address Extraction
    private func extractAddress(from text: String) -> String? {
        // Try to extract full address
        let addressPatterns = [
            #"([A-Za-z0-9\s,]+,\s*[A-Za-z\s]+,\s*[A-Za-z\s]+)"#,  // "Street, City, Country"
            #"([A-Za-z\s]+,\s*[A-Za-z\s]+)"#,  // "City, Country"
        ]
        
        for pattern in addressPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let address = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !address.isEmpty && address.count > 5 {
                    return address
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Post ID Extraction
    private func extractPostId(from url: String) -> String? {
        // Extract post ID from Instagram URL: instagram.com/p/POST_ID/
        let patterns = [
            #"instagram\.com/p/([A-Za-z0-9_-]+)"#,
            #"tiktok\.com/@[^/]+/video/(\d+)"#,
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        
        return nil
    }
    
    // MARK: - Video Info Extraction
    private func extractVideoInfo(from url: String) -> (title: String?, description: String?) {
        // Try to get video title and description from clipboard
        guard let clipboardText = UIPasteboard.general.string,
              !clipboardText.isEmpty else {
            print("⚠️ No clipboard text found")
            return (nil, nil)
        }
        
        print("📋 Clipboard text: \(clipboardText.prefix(200))")
        
        var title: String?
        var description: String?
        
        // Extract title (usually first line or before newline)
        let lines = clipboardText.components(separatedBy: .newlines)
        print("📋 Clipboard has \(lines.count) lines")
        
        // For TikTok, when you copy a link, the format is usually:
        // "Video Title/Caption\n\nhttps://tiktok.com/..."
        // OR just the URL if copied from share sheet
        
        // Check if first line is a URL - if so, look for title in other lines
        let firstLine = lines.first ?? ""
        let isFirstLineURL = firstLine.contains("http://") || firstLine.contains("https://") || firstLine.contains("tiktok.com") || firstLine.contains("instagram.com")
        
        if isFirstLineURL {
            // First line is URL, title might be in second line or we need to extract from URL
            print("📋 First line is URL, checking other lines for title")
            
            // Look for title in lines after the URL
            for (index, line) in lines.enumerated() {
                if index == 0 { continue } // Skip URL line
                
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                // Skip empty lines
                if trimmed.isEmpty { continue }
                
                // Skip if it's another URL
                if trimmed.contains("http://") || trimmed.contains("https://") {
                    continue
                }
                
                // Skip location markers
                if trimmed.contains("📍") {
                    break
                }
                
                // Skip social media text
                if trimmed.lowercased().contains("view on") ||
                   trimmed.lowercased().contains("watch on") ||
                   trimmed.lowercased().contains("see more") {
                    continue
                }
                
                // This could be the title
                if !trimmed.isEmpty && trimmed.count > 3 {
                    title = trimmed
                    print("✅ Found title in line \(index): \(trimmed.prefix(50))")
                    break
                }
            }
            
            // If no title found in other lines, try to extract from URL or use a default
            if title == nil {
                // Try to get video ID from URL and create a title
                if let videoId = extractVideoIdFromURL(url) {
                    title = "TikTok Video \(videoId)"
                } else {
                    title = "TikTok Video"
                }
            }
        } else {
            // First line is not a URL, it's likely the title
            var cleaned = firstLine
                .replacingOccurrences(of: "View on Instagram", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "View on TikTok", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Watch on TikTok", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Watch on Instagram", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            
            // Remove URLs if they appear in the first line
            if cleaned.contains("http://") || cleaned.contains("https://") {
                if let urlRange = cleaned.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
                    cleaned.removeSubrange(urlRange)
                }
            }
            
            cleaned = cleaned.trimmingCharacters(in: .whitespaces)
            
            // Use as title if it's meaningful
            if !cleaned.isEmpty && cleaned.count > 3 && !cleaned.hasPrefix("http") {
                title = cleaned
                print("✅ Found title in first line: \(cleaned.prefix(50))")
            }
        }
        
        // Extract description (rest of the text, excluding location info)
        if lines.count > 1 {
            var descLines: [String] = []
            
            for line in lines.dropFirst() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                // Skip empty lines
                if trimmed.isEmpty { continue }
                
                // Stop if we hit location markers
                if trimmed.contains("📍") || 
                   trimmed.lowercased().contains("location:") {
                    break
                }
                
                // Skip common social media text and URLs
                if trimmed.lowercased().contains("view on") ||
                   trimmed.lowercased().contains("watch on") ||
                   trimmed.lowercased().contains("see more") ||
                   trimmed.lowercased().contains("open in") ||
                   trimmed.contains("http://") ||
                   trimmed.contains("https://") ||
                   trimmed.contains("tiktok.com") ||
                   trimmed.contains("instagram.com") {
                    continue
                }
                
                // Skip if it's just hashtags or mentions at the end
                if trimmed.hasPrefix("#") && trimmed.count < 30 {
                    continue
                }
                
                descLines.append(trimmed)
            }
            
            if !descLines.isEmpty {
                let fullDescription = descLines.joined(separator: "\n")
                // Only use as description if it's different from title
                if fullDescription != title {
                    description = fullDescription
                }
            }
        } else if clipboardText.count > 50 && clipboardText != title {
            // If single line but long and different from title, use as description
            description = clipboardText
        }
        
        print("📋 Final title: \(title ?? "nil"), description: \(description?.prefix(50) ?? "nil")")
        return (title, description)
    }
    
    // MARK: - Extract Video ID from URL
    private func extractVideoIdFromURL(_ url: String) -> String? {
        // TikTok URL format: https://www.tiktok.com/@username/video/VIDEO_ID
        let patterns = [
            #"tiktok\.com/@[^/]+/video/(\d+)"#,
            #"tiktok\.com/t/([A-Za-z0-9]+)"#,
            #"vm\.tiktok\.com/([A-Za-z0-9]+)"#,
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        
        return nil
    }
    
    // MARK: - Share Trip to Social Media
    func shareTrip(_ trip: TripModel) -> [Any] {
        var shareItems: [Any] = []
        
        // Create share text
        let shareText = """
        ✈️ \(trip.name)
        
        📅 \(trip.formattedDateRange)
        📍 \(trip.destinations?.map { $0.name }.joined(separator: ", ") ?? "No destinations")
        
        Planned with Itinero 🗺️
        """
        
        shareItems.append(shareText)
        
        // Add trip image if available
        // Note: coverImageData not available on TripModel
        // if let imageData = trip.coverImageData,
        //    let image = UIImage(data: imageData) {
        //     shareItems.append(image)
        // }
        
        return shareItems
    }
    
    // MARK: - Web Scraping
    private func scrapeURL(_ urlString: String) async -> ScrapedData {
        guard let url = URL(string: urlString) else {
            return ScrapedData()
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        do {
            print("🌐 Fetching webpage: \(urlString)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("⚠️ Failed to fetch or parse HTML")
                return ScrapedData()
            }
            
            print("✅ Successfully fetched HTML (\(htmlString.count) characters)")
            
            // Parse HTML to extract metadata
            return parseHTML(htmlString, url: urlString)
            
        } catch {
            print("❌ Error fetching URL: \(error.localizedDescription)")
            return ScrapedData()
        }
    }
    
    // MARK: - HTML Parsing
    private func parseHTML(_ html: String, url: String) -> ScrapedData {
        var data = ScrapedData()
        
        // Extract Open Graph tags and meta tags
        // og:title, og:description, og:image
        // twitter:title, twitter:description
        // title tag
        
        // Extract og:title
        if let ogTitle = extractMetaTag(html: html, property: "og:title") {
            data.title = ogTitle
            print("📝 Found og:title: \(ogTitle.prefix(50))")
        }
        
        // Extract og:description
        if let ogDescription = extractMetaTag(html: html, property: "og:description") {
            data.description = ogDescription
            print("📝 Found og:description: \(ogDescription.prefix(50))")
        }
        
        // Extract og:image
        if let ogImage = extractMetaTag(html: html, property: "og:image") {
            data.imageURL = ogImage
            print("🖼️ Found og:image: \(ogImage.prefix(50))")
        }
        
        // Extract title tag if og:title not found
        if data.title == nil {
            if let title = extractTitleTag(html: html) {
                data.title = title
                print("📝 Found title tag: \(title.prefix(50))")
            }
        }
        
        // Extract description from meta description if og:description not found
        if data.description == nil {
            if let metaDescription = extractMetaTag(html: html, name: "description") {
                data.description = metaDescription
                print("📝 Found meta description: \(metaDescription.prefix(50))")
            }
        }
        
        // For TikTok, try to extract location from structured data
        if url.contains("tiktok.com") {
            // TikTok sometimes has location in JSON-LD or meta tags
            if let location = extractLocationFromHTML(html: html) {
                data.location = location
            }
        }
        
        return data
    }
    
    // MARK: - HTML Meta Tag Extraction
    private func extractMetaTag(html: String, property: String? = nil, name: String? = nil) -> String? {
        let pattern: String
        if let property = property {
            pattern = #"<meta\s+property=["']\(property)["']\s+content=["']([^"']+)["']"#
        } else if let name = name {
            pattern = #"<meta\s+name=["']\(name)["']\s+content=["']([^"']+)["']"#
        } else {
            return nil
        }
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let content = String(html[range])
            // Decode HTML entities
            return decodeHTMLEntities(content)
        }
        
        return nil
    }
    
    // MARK: - Title Tag Extraction
    private func extractTitleTag(html: String) -> String? {
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let title = String(html[range])
            // Remove common suffixes
            let cleaned = title
                .replacingOccurrences(of: " | TikTok", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: " | Instagram", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: " on TikTok", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: " on Instagram", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            return decodeHTMLEntities(cleaned)
        }
        
        return nil
    }
    
    // MARK: - Location Extraction from HTML
    private func extractLocationFromHTML(html: String) -> String? {
        // Look for location in various formats
        let patterns = [
            #"location["']\s*:\s*["']([^"']+)"#,
            #"📍\s*([A-Za-z0-9\s,]+)"#,
            #"address["']\s*:\s*["']([^"']+)"#,
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let location = String(html[range]).trimmingCharacters(in: .whitespaces)
                if !location.isEmpty && location.count > 2 {
                    return decodeHTMLEntities(location)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - HTML Entity Decoding
    private func decodeHTMLEntities(_ string: String) -> String {
        var decoded = string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&apos;", with: "'")
        
        // Decode numeric entities (e.g., &#8217;)
        if let regex = try? NSRegularExpression(pattern: #"&#(\d+);"#) {
            let nsString = decoded as NSString
            let matches = regex.matches(in: decoded, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var result = decoded
            // Process matches in reverse order to maintain indices
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let codeRange = match.range(at: 1)
                    let codeString = nsString.substring(with: codeRange)
                    if let code = Int(codeString),
                       let unicodeScalar = UnicodeScalar(code) {
                        let replacement = String(Character(unicodeScalar))
                        let fullRange = match.range
                        result = (result as NSString).replacingCharacters(in: fullRange, with: replacement)
                    }
                }
            }
            decoded = result
        }
        
        return decoded
    }
}

// MARK: - Scraped Data Structure
private struct ScrapedData {
    var title: String?
    var description: String?
    var imageURL: String?
    var location: String?
    var latitude: Double?
    var longitude: Double?
}

// MARK: - Extracted Location Model
struct ExtractedLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let sourceURL: String
    let sourceType: SocialMediaSource
    let imageURL: String?
    let videoTitle: String?  // Video/post title
    let description: String?  // Video/post description
}

enum SocialMediaSource {
    case instagram
    case tiktok
    case generic
    
    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .generic: return "link"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram: return Color(red: 0.8, green: 0.3, blue: 0.6)
        case .tiktok: return Color.black
        case .generic: return Color.blue
        }
    }
}

