//
//  ContentFilterManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation

@MainActor
class ContentFilterManager: ObservableObject {
    static let shared = ContentFilterManager()
    
    // Comprehensive list of inappropriate words and phrases
    private let blockedWords: Set<String> = [
        // Profanity
        "fuck", "fucking", "fucked", "fucker", "fuckers",
        "shit", "shitting", "shitted", "shitty",
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
        "cunt", "cunts",
        "whore", "whores",
        "slut", "sluts",
        "nigger", "niggers", "nigga", "niggas",
        "retard", "retarded", "retards",
        "gay", "gays", "fag", "fags", "faggot", "faggots",
        "lesbian", "lesbians",
        "homo", "homos",
        "tranny", "trannies",
        "dyke", "dykes",
        // Sexual content
        "sex", "sexual", "sexually",
        "porn", "porno", "pornography",
        "masturbat", "masturbation",
        "orgasm", "orgasms",
        "erotic", "erotica",
        "nude", "nudes", "nudity",
        "naked", "nakedness",
        "penis", "penises",
        "vagina", "vaginas",
        "breast", "breasts",
        "boob", "boobs",
        "nipple", "nipples",
        "clitoris", "clitorises",
        "ejaculat", "ejaculation",
        "sperm", "sperms",
        "cum", "cums", "cumming",
        "blowjob", "blowjobs",
        "handjob", "handjobs",
        "oral sex",
        "anal sex",
        "rape", "rapes", "raped", "raping", "rapist",
        "molest", "molestation", "molested",
        "pedophil", "pedophile", "pedophilia",
        // Violence and threats
        "kill", "kills", "killed", "killing", "killer",
        "murder", "murders", "murdered", "murdering", "murderer",
        "die", "dies", "died", "dying", "death",
        "suicide", "suicides", "suicidal",
        "bomb", "bombs", "bombing", "bombed",
        "terrorist", "terrorists", "terrorism",
        "shoot", "shoots", "shot", "shooting",
        "gun", "guns",
        "weapon", "weapons",
        "knife", "knives",
        "stab", "stabs", "stabbed", "stabbing",
        "beat", "beats", "beaten", "beating",
        "torture", "tortures", "tortured", "torturing",
        "abuse", "abuses", "abused", "abusing",
        // Hate speech
        "hate", "hates", "hated", "hating",
        "racist", "racism", "racists",
        "nazi", "nazis",
        "kkk",
        "white supremacist",
        "black supremacist",
        // Drug-related
        "cocaine", "coke",
        "heroin",
        "meth", "methamphetamine",
        "crack",
        "lsd",
        "ecstasy",
        "marijuana", "weed", "pot",
        "drug", "drugs", "drugged", "drugging",
        // Other inappropriate
        "stupid", "stupidity",
        "idiot", "idiots", "idiotic",
        "moron", "morons",
        "dumb", "dumber", "dumbest",
        "ugly", "uglier", "ugliest",
        "fat", "fatter", "fattest",
        "obese", "obesity",
        "anorexic", "anorexia",
        "bulimic", "bulimia"
    ]
    
    private init() {}
    
    /// Check if text contains inappropriate content
    func containsInappropriateContent(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let words = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        for word in words {
            let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && blockedWords.contains(trimmed) {
                return true
            }
            
            // Check for partial matches (e.g., "f*ck", "sh*t")
            for blockedWord in blockedWords {
                if trimmed.contains(blockedWord) || blockedWord.contains(trimmed) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Filter inappropriate content from text
    func filterContent(_ text: String) -> String {
        guard containsInappropriateContent(text) else {
            return text
        }
        
        var filtered = text
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        for word in words {
            let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmed.isEmpty && blockedWords.contains(trimmed) {
                let replacement = String(repeating: "*", count: min(trimmed.count, 4))
                filtered = filtered.replacingOccurrences(
                    of: word,
                    with: replacement,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        
        return filtered
    }
    
    /// Validate text and return error message if inappropriate
    func validateContent(_ text: String) -> (isValid: Bool, errorMessage: String?) {
        if containsInappropriateContent(text) {
            return (false, "Your message contains inappropriate content. Please use respectful language.")
        }
        return (true, nil)
    }
}










