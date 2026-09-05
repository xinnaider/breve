import Foundation

enum QuizFactory {
    static func options(for card: Card, pool: [Card]) -> [QuizOption] {
        if let spec = card.quiz, spec.options.count >= 2,
           spec.correctIndex >= 0, spec.correctIndex < spec.options.count {
            return spec.options.enumerated().map { index, text in
                QuizOption(id: "\(card.id)-\(index)", text: text, correct: index == spec.correctIndex)
            }.shuffled()
        }

        let correct = clip(card.verso)
        guard !correct.isEmpty else { return [] }

        var used: Set<String> = [normalize(correct)]
        var distractors: [String] = []
        let sameTopic = pool.filter { $0.topicId == card.topicId && $0.id != card.id }
        let sameType = pool.filter { $0.objectId == card.objectId && $0.id != card.id }
        for other in sameTopic + sameType {
            let text = clip(other.verso)
            let key = normalize(text)
            guard !key.isEmpty, !used.contains(key) else { continue }
            used.insert(key)
            distractors.append(text)
            if distractors.count == 3 { break }
        }

        guard !distractors.isEmpty else { return [] }

        var options = [QuizOption(id: "\(card.id)-ok", text: correct, correct: true)]
        for (index, text) in distractors.enumerated() {
            options.append(QuizOption(id: "\(card.id)-x\(index)", text: text, correct: false))
        }
        return options.shuffled()
    }

    private static func clip(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let first = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).first
            .map { String($0).trimmingCharacters(in: .whitespaces) } ?? trimmed
        let sentence = first.hasSuffix(".") || first.hasSuffix("?") ? first : first + "."
        if sentence.count <= 140 { return sentence }
        return String(sentence.prefix(137)).trimmingCharacters(in: .whitespaces) + "..."
    }

    private static func normalize(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
