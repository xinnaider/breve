import Foundation

enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case pt
    case en

    static let fallback = AppLanguage.pt

    init(stored raw: String?) {
        self = AppLanguage(rawValue: raw ?? "") ?? .fallback
    }
}
