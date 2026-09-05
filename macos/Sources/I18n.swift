import Foundation
import Yams

enum I18n {
    nonisolated(unsafe) private static var table: [String: [String: String]] = [:]

    static func load(from bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "i18n", withExtension: "yaml")
            ?? bundle.url(forResource: "i18n", withExtension: "yaml", subdirectory: "Resources")
        else { return }
        guard let text = try? String(contentsOf: url, encoding: .utf8),
              let parsed = try? YAMLDecoder().decode([String: [String: String]].self, from: text)
        else { return }
        table = parsed
    }

    static func t(
        _ key: String,
        language: AppLanguage,
        _ args: [String: String] = [:]
    ) -> String {
        let row = table[key]
        var raw = row?[language.rawValue] ?? row?[AppLanguage.fallback.rawValue] ?? key
        for (name, value) in args {
            raw = raw.replacingOccurrences(of: "{\(name)}", with: value)
        }
        return raw
    }
}
