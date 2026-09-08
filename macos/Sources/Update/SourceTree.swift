import Foundation

enum SourceTree {
    static func marketingVersion(atRoot root: URL) throws -> String {
        let yaml = root.appendingPathComponent("macos/project.yml")
        let text = try String(contentsOf: yaml, encoding: .utf8)
        guard let match = text.range(of: #"MARKETING_VERSION:\s*"([^"]+)""#, options: .regularExpression) else {
            throw UpdateError.installFailed("MARKETING_VERSION missing in project.yml.")
        }
        let line = String(text[match])
        guard let quote = line.split(separator: "\"").dropFirst().first else {
            throw UpdateError.installFailed("MARKETING_VERSION missing in project.yml.")
        }
        return String(quote)
    }

    static func requireMarketing(_ root: URL, expected: String) throws {
        let found = try marketingVersion(atRoot: root)
        guard AppVersion(found) == AppVersion(expected) else {
            throw UpdateError.versionMismatch(expected: expected, found: found)
        }
    }
}
