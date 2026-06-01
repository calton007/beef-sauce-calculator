import Foundation

struct NutritionLabelCandidate: Equatable, Identifiable {
    var id: String {
        "\(sodiumMilligrams)-\(referenceGrams ?? -1)-\(sourceText)"
    }

    var sodiumMilligrams: Double
    var referenceGrams: Double?
    var sourceText: String
    var score: Int
}

enum NutritionLabelParser {
    static func candidates(from recognizedText: String) -> [NutritionLabelCandidate] {
        let lines = normalizedLines(from: recognizedText)
        let globalReference = bestReference(in: lines.joined(separator: " "))
        var candidates: [NutritionLabelCandidate] = []

        for (index, line) in lines.enumerated() {
            guard containsSodiumKeyword(line), let sodium = sodiumValue(in: line) else {
                continue
            }

            let nearbyText = nearbyText(for: index, in: lines)
            let reference = bestReference(in: line) ?? bestReference(in: nearbyText) ?? globalReference
            let score = candidateScore(line: line, nearbyText: nearbyText, hasReference: reference != nil)
            candidates.append(
                NutritionLabelCandidate(
                    sodiumMilligrams: sodium,
                    referenceGrams: reference,
                    sourceText: line,
                    score: score
                )
            )
        }

        return deduplicated(candidates)
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.sourceText.count < rhs.sourceText.count
                }
                return lhs.score > rhs.score
            }
            .prefix(3)
            .map { $0 }
    }

    private static func normalizedLines(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "毫克", with: "mg")
            .replacingOccurrences(of: "克", with: "g")
            .replacingOccurrences(of: "／", with: "/")
            .replacingOccurrences(of: "：", with: ":")
            .components(separatedBy: .newlines)
            .map { normalizeFullWidth($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func normalizeFullWidth(_ value: String) -> String {
        var result = ""
        for scalar in value.unicodeScalars {
            let code = scalar.value
            if code == 0x3000 {
                result.append(" ")
            } else if (0xFF01...0xFF5E).contains(code), let converted = UnicodeScalar(code - 0xFEE0) {
                result.unicodeScalars.append(converted)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    private static func containsSodiumKeyword(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("钠") || lower.contains("sodium") || lower.range(of: #"\bna\b"#, options: .regularExpression) != nil
    }

    private static func sodiumValue(in text: String) -> Double? {
        let patterns = [
            #"(?:钠|sodium|\bna\b)\D{0,24}(\d+(?:\.\d+)?)\s*(?:mg)?"#,
            #"(\d+(?:\.\d+)?)\s*(?:mg)\D{0,24}(?:钠|sodium|\bna\b)"#
        ]

        for pattern in patterns {
            if let value = firstNumber(matching: pattern, in: text, options: [.caseInsensitive]) {
                return value
            }
        }
        return nil
    }

    private static func bestReference(in text: String) -> Double? {
        let patterns = [
            #"(?:每|per)\s*(\d+(?:\.\d+)?)\s*g"#,
            #"(?:每份|serving|serve)\D{0,12}(\d+(?:\.\d+)?)\s*g"#,
            #"/\s*(\d+(?:\.\d+)?)\s*g"#
        ]

        for pattern in patterns {
            if let value = firstNumber(matching: pattern, in: text, options: [.caseInsensitive]) {
                return value
            }
        }
        return nil
    }

    private static func nearbyText(for index: Int, in lines: [String]) -> String {
        let start = max(0, index - 1)
        let end = min(lines.count - 1, index + 1)
        return lines[start...end].joined(separator: " ")
    }

    private static func candidateScore(line: String, nearbyText: String, hasReference: Bool) -> Int {
        var score = 0
        if hasReference { score += 20 }
        if line.lowercased().contains("mg") { score += 10 }
        if bestReference(in: line) != nil { score += 8 }
        if nearbyText.contains("营养") || nearbyText.lowercased().contains("nutrition") { score += 4 }
        return score
    }

    private static func firstNumber(
        matching pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Double(text[valueRange])
    }

    private static func deduplicated(_ candidates: [NutritionLabelCandidate]) -> [NutritionLabelCandidate] {
        var seen = Set<String>()
        var result: [NutritionLabelCandidate] = []
        for candidate in candidates {
            let key = "\(candidate.sodiumMilligrams)-\(candidate.referenceGrams ?? -1)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(candidate)
        }
        return result
    }
}
