import Foundation

struct UserConfig: Codable, Equatable {
    var bootstrapped: Bool
    var sel: [String: Slot]
    var lastShownId: String?
    var dockEdge: String?
    var dockAlong: Double?
    var learnQuiz: Bool?
    var learnInfo: Bool?
    var language: String?

    struct Slot: Codable, Equatable {
        var on: Bool
        var topics: [String]
    }

    static let defaultsKey = "petzinho.config.v1"

    // Isolate manual first-launch checks from the student's saved preferences.
    static var storage: UserDefaults {
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["PETZINHO_DEFAULTS_SUITE"],
           !suite.isEmpty, let defaults = UserDefaults(suiteName: suite) {
            return defaults
        }
        #endif
        return .standard
    }

    static func load(from defaults: UserDefaults = UserConfig.storage) -> UserConfig? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(UserConfig.self, from: data)
    }

    func save(to defaults: UserDefaults = UserConfig.storage) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    static func empty(types: [StudyType]) -> UserConfig {
        UserConfig(
            bootstrapped: false,
            sel: Dictionary(uniqueKeysWithValues: types.map { ($0.id, Slot(on: false, topics: [])) }),
            lastShownId: nil,
            dockEdge: DockAnchor.fallback.edge.rawValue,
            dockAlong: Double(DockAnchor.fallback.along),
            learnQuiz: true,
            learnInfo: true,
            language: AppLanguage.fallback.rawValue
        )
    }
}
