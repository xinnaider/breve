import Foundation

struct AppVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    let parts: [Int]
    let raw: String

    init(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutV = trimmed.hasPrefix("v") || trimmed.hasPrefix("V")
            ? String(trimmed.dropFirst())
            : trimmed
        self.raw = withoutV
        self.parts = withoutV.split(separator: ".").map { Int($0) ?? 0 }
    }

    var description: String { raw }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        for index in 0..<count {
            let a = index < lhs.parts.count ? lhs.parts[index] : 0
            let b = index < rhs.parts.count ? rhs.parts[index] : 0
            if a != b { return a < b }
        }
        return false
    }
}

enum VersionPolicy {
    static func isStableTag(_ tag: String) -> Bool {
        let value = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        return value.range(of: #"^[0-9]+\.[0-9]+\.[0-9]+$"#, options: .regularExpression) != nil
    }

    static func tagToMarketing(_ tag: String) -> String {
        AppVersion(tag).raw
    }
}
