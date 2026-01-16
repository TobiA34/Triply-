//
//  ContentFilter.swift
//  Triply
//
//  Content filter to block offensive language
//

import Foundation

public struct ContentFilter {
    
    // Comprehensive list of offensive terms to filter
    private static let blockedTerms: Set<String> = [
        // Swear words (common profanity)
        "fuck", "fucking", "fucked", "fucker", "fuckers",
        "shit", "shitting", "shitted", "shitter",
        "damn", "damned", "dammit",
        "hell", "hells",
        "ass", "asses", "asshole", "assholes",
        "bitch", "bitches", "bitching",
        "bastard", "bastards",
        "crap", "crappy",
        "piss", "pissing", "pissed",
        "dick", "dicks", "dickhead",
        "cock", "cocks",
        "pussy", "pussies",
        "tits", "tit",
        "whore", "whores",
        "slut", "sluts",
        "cunt", "cunts",
        
        // Homophobic terms
        "fag", "fags", "faggot", "faggots", "faggy",
        "homo", "homos",
        "queer", "queers", "queered", // Note: "queer" can be reclaimed, but filtering for safety
        "dyke", "dykes",
        "lesbo", "lesbos",
        
        // Racist terms
        "nigger", "niggers", "nigga", "niggas", "niggaz",
        "chink", "chinks",
        "gook", "gooks",
        "kike", "kikes",
        "spic", "spics",
        "wetback", "wetbacks",
        "towelhead", "towelheads",
        "sandnigger", "sandniggers",
        "paki", "pakis",
        "gypsy", "gypsies", // Can be offensive when used pejoratively
        "jap", "japs", // Offensive slur
        "chink", "chinks",
        "gook", "gooks",
        
        // Islamophobic terms
        "terrorist", "terrorists", // Context-dependent, but filtering for safety
        "islamist", "islamists", // Can be used pejoratively
        "muzzie", "muzzies",
        "raghead", "ragheads",
        "towelhead", "towelheads",
        "sandnigger", "sandniggers",
        "cameljockey", "cameljockeys",
        "bomber", "bombers", // Context-dependent
        
        // Transphobic terms
        "tranny", "trannies", "trannys",
        "shemale", "shemales",
        "ladyboy", "ladyboys",
        "trap", "traps", // When used transphobically
        "it", // When used to refer to trans people
        "he-she", "heshe",
        "she-he", "shehe",
        
        // Additional offensive terms
        "retard", "retarded", "retards",
        "retardation",
        "spastic", "spastics",
        "mongoloid", "mongoloids",
        "cripple", "cripples",
        "gimp", "gimps",
        "midget", "midgets",
        "dwarf", "dwarfs", // Context-dependent
    ]
    
    // Check if text contains blocked terms
    public static func containsBlockedContent(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let words = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        for word in words {
            if blockedTerms.contains(word) {
                return true
            }
        }
        
        // Also check for blocked terms within the text (handles cases like "f*ck")
        for term in blockedTerms {
            if lowercased.contains(term) {
                return true
            }
        }
        
        return false
    }
    
    // Filter and replace blocked content
    static func filterContent(_ text: String) -> String {
        var filtered = text
        let lowercased = text.lowercased()
        
        for term in blockedTerms {
            let regex = try? NSRegularExpression(pattern: "\\b\(term)\\b", options: .caseInsensitive)
            if let regex = regex {
                let range = NSRange(location: 0, length: text.utf16.count)
                filtered = regex.stringByReplacingMatches(
                    in: filtered,
                    options: [],
                    range: range,
                    withTemplate: String(repeating: "*", count: term.count)
                )
            }
        }
        
        return filtered
    }
    
    // Validate text and return error message if blocked
    static func validate(_ text: String) -> (isValid: Bool, errorMessage: String?) {
        if containsBlockedContent(text) {
            return (false, "Your message contains inappropriate language. Please revise your text.")
        }
        return (true, nil)
    }
}

