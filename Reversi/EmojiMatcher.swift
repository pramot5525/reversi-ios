import NaturalLanguage

/// Uses Apple's NLEmbedding (word vectors) to semantically match words to emoji.
/// Fallback: dictionary lookup for common words and exact Unicode name matches.
final class EmojiMatcher: @unchecked Sendable {
    static let shared = EmojiMatcher()

    private let embedding: NLEmbedding?

    // Pre-built lookup: keyword → emoji
    private let directMap: [String: String]
    // All emoji with their searchable keywords for NLEmbedding matching
    private let emojiKeywords: [(emoji: String, keywords: [String])]

    private init() {
        embedding = NLEmbedding.wordEmbedding(for: .english)

        var map: [String: String] = [:]
        var keywords: [(String, [String])] = []

        for piece in PieceOption.allPieces {
            let name = piece.unicodeName
            guard !name.isEmpty else { continue }
            let words = name.lowercased().split(separator: " ").map(String.init)

            // Direct map: full name and each word (3+ chars)
            map[name.lowercased()] = piece.emoji
            for w in words where w.count >= 3 {
                if map[w] == nil { map[w] = piece.emoji }
            }

            keywords.append((piece.emoji, words))
        }

        // Common overrides for better matching
        let overrides: [String: String] = [
            "love": "\u{2764}\u{FE0F}", "heart": "\u{2764}\u{FE0F}",
            "happy": "\u{1F60A}", "sad": "\u{1F622}",
            "angry": "\u{1F620}", "fire": "\u{1F525}",
            "star": "\u{2B50}", "sun": "\u{2600}\u{FE0F}",
            "moon": "\u{1F319}", "rain": "\u{1F327}\u{FE0F}",
            "snow": "\u{2744}\u{FE0F}", "tree": "\u{1F333}",
            "flower": "\u{1F338}", "rose": "\u{1F339}",
            "dog": "\u{1F436}", "cat": "\u{1F431}",
            "fish": "\u{1F41F}", "bird": "\u{1F426}",
            "car": "\u{1F697}", "house": "\u{1F3E0}",
            "book": "\u{1F4D6}", "music": "\u{1F3B5}",
            "phone": "\u{1F4F1}", "computer": "\u{1F4BB}",
            "time": "\u{23F0}", "money": "\u{1F4B0}",
            "food": "\u{1F354}", "water": "\u{1F4A7}",
            "coffee": "\u{2615}", "pizza": "\u{1F355}",
            "cake": "\u{1F382}", "party": "\u{1F389}",
            "gift": "\u{1F381}", "sleep": "\u{1F634}",
            "think": "\u{1F914}", "laugh": "\u{1F602}",
            "cry": "\u{1F62D}", "wave": "\u{1F44B}",
            "yes": "\u{2705}", "no": "\u{274C}",
            "ok": "\u{1F44C}", "cool": "\u{1F60E}",
            "hello": "\u{1F44B}", "hi": "\u{1F44B}",
            "bye": "\u{1F44B}", "thanks": "\u{1F64F}",
            "please": "\u{1F64F}", "sorry": "\u{1F614}",
            "wow": "\u{1F62E}", "lol": "\u{1F602}",
            "haha": "\u{1F604}", "run": "\u{1F3C3}",
            "eat": "\u{1F37D}\u{FE0F}", "drink": "\u{1F377}",
            "play": "\u{1F3AE}", "sing": "\u{1F3A4}",
            "dance": "\u{1F483}", "fly": "\u{2708}\u{FE0F}",
            "drive": "\u{1F697}", "work": "\u{1F4BC}",
            "study": "\u{1F4DA}", "write": "\u{270D}\u{FE0F}",
            "read": "\u{1F4D6}", "fight": "\u{1F4A5}",
            "win": "\u{1F3C6}", "lose": "\u{1F61E}",
            "big": "\u{1F4AA}", "small": "\u{1F90F}",
            "fast": "\u{26A1}", "slow": "\u{1F422}",
            "hot": "\u{1F975}", "cold": "\u{1F976}",
            "beautiful": "\u{1F60D}", "ugly": "\u{1F648}",
            "good": "\u{1F44D}", "bad": "\u{1F44E}",
            "new": "\u{2728}", "old": "\u{1F9D3}",
            "rich": "\u{1F4B0}", "poor": "\u{1F622}",
            "strong": "\u{1F4AA}", "weak": "\u{1F62A}",
            "smart": "\u{1F9E0}", "king": "\u{1F451}",
            "queen": "\u{1F478}", "baby": "\u{1F476}",
            "family": "\u{1F46A}", "friend": "\u{1F91D}",
            "world": "\u{1F30D}", "home": "\u{1F3E0}",
            "school": "\u{1F3EB}", "hospital": "\u{1F3E5}",
            "night": "\u{1F303}", "day": "\u{2600}\u{FE0F}",
            "morning": "\u{1F305}", "evening": "\u{1F307}",
            "spring": "\u{1F338}", "summer": "\u{2600}\u{FE0F}",
            "autumn": "\u{1F342}", "winter": "\u{2744}\u{FE0F}",
            "i": "\u{1F464}", "you": "\u{1F449}",
            "we": "\u{1F465}", "they": "\u{1F465}",
            "and": "\u{2795}", "is": "=",
        ]
        for (word, emoji) in overrides {
            map[word] = emoji
        }

        self.directMap = map
        self.emojiKeywords = keywords
    }

    // MARK: - Convert

    /// Convert a text string into an array of (emoji, sourceWord) pairs.
    /// Supports multi-word phrase matching (e.g. "ice cream" → 🍦 as one emoji).
    func convert(_ text: String) -> [(String, String)] {
        let words = text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }

        var result: [(String, String)] = []
        var i = 0

        while i < words.count {
            let clean = words[i]
            guard !clean.isEmpty else { i += 1; continue }

            // Try 3-word phrase match first
            if i + 2 < words.count {
                let phrase3 = "\(words[i]) \(words[i+1]) \(words[i+2])"
                if let emoji = directMap[phrase3] {
                    result.append((emoji, phrase3))
                    i += 3
                    continue
                }
            }

            // Try 2-word phrase match
            if i + 1 < words.count {
                let phrase2 = "\(words[i]) \(words[i+1])"
                if let emoji = directMap[phrase2] {
                    result.append((emoji, phrase2))
                    i += 2
                    continue
                }
            }

            // Single word match
            if let emoji = directMap[clean] {
                result.append((emoji, clean))
                i += 1
                continue
            }

            // Already an emoji
            if clean.unicodeScalars.count == 1,
               let scalar = clean.unicodeScalars.first,
               scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                result.append((clean, clean))
                i += 1
                continue
            }

            // NLEmbedding semantic search
            if let match = semanticMatch(for: clean) {
                result.append((match, clean))
                i += 1
                continue
            }

            // Sentiment fallback
            let sentimentEmoji = sentimentMatch(for: clean)
            result.append((sentimentEmoji, clean))
            i += 1
        }

        return result
    }

    // MARK: - NLEmbedding Semantic Match

    /// Find the best emoji match using word embedding distance.
    private func semanticMatch(for word: String) -> String? {
        guard let embedding else { return nil }
        guard embedding.contains(word) else { return nil }

        var bestEmoji: String?
        var bestDistance = Double.greatestFiniteMagnitude

        // Compare the input word against each emoji's keywords
        for (emoji, keywords) in emojiKeywords {
            for keyword in keywords {
                let dist = embedding.distance(between: word, and: keyword)
                if dist < bestDistance {
                    bestDistance = dist
                    bestEmoji = emoji
                }
            }
        }

        // Only accept if distance is reasonably close (threshold)
        if bestDistance < 1.2, let emoji = bestEmoji {
            return emoji
        }
        return nil
    }

    // MARK: - Sentiment Analysis Fallback

    /// Analyze the sentiment of a word and return a mood emoji.
    private func sentimentMatch(for word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = word
        let (tag, _) = tagger.tag(at: word.startIndex, unit: .word, scheme: .sentimentScore)

        let score = Double(tag?.rawValue ?? "0") ?? 0

        // Map sentiment score (-1.0 to 1.0) to emoji
        if score > 0.5 { return "\u{1F60D}" }       // very positive → smiling face with heart-eyes
        if score > 0.2 { return "\u{1F60A}" }        // positive → smiling face
        if score > 0.05 { return "\u{1F642}" }       // slightly positive → slightly smiling
        if score < -0.5 { return "\u{1F621}" }       // very negative → angry
        if score < -0.2 { return "\u{1F61E}" }       // negative → disappointed
        if score < -0.05 { return "\u{1F610}" }      // slightly negative → neutral

        // Neutral: use a thought bubble
        return "\u{1F4AD}"                             // thought balloon
    }
}
