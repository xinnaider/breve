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

    static let defaultsKey = "breve.config.v1"
    static let legacyDefaultsKey = "petzinho.config.v1"
    static let legacySuiteName = "dev.fordevs.petzinho"

    static var storage: UserDefaults {
        #if DEBUG
        if let suite = DebugEnv.value("DEFAULTS_SUITE"),
           let defaults = UserDefaults(suiteName: suite) {
            return defaults
        }
        #endif
        return .standard
    }

    static func load(from defaults: UserDefaults = UserConfig.storage) -> UserConfig? {
        let legacy: UserDefaults?
        #if DEBUG
        if DebugEnv.value("DEFAULTS_SUITE") != nil {
            legacy = nil
        } else {
            legacy = UserDefaults(suiteName: legacySuiteName)
        }
        #else
        legacy = UserDefaults(suiteName: legacySuiteName)
        #endif
        return load(from: defaults, legacy: legacy)
    }

    static func load(from defaults: UserDefaults, legacy: UserDefaults?) -> UserConfig? {
        if let config = decode(defaults.data(forKey: defaultsKey)) {
            return config
        }
        guard let legacy,
              let config = decode(
                legacy.data(forKey: legacyDefaultsKey) ?? legacy.data(forKey: defaultsKey)
              ) else {
            return nil
        }
        config.save(to: defaults)
        return config
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
            dockEdge: "right",
            dockAlong: 0.78,
            learnQuiz: true,
            learnInfo: true,
            language: AppLanguage.fallback.rawValue
        )
    }

    private static func decode(_ data: Data?) -> UserConfig? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(UserConfig.self, from: data)
    }
}

enum DebugEnv {
    static func value(_ name: String) -> String? {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let value = env["BREVE_\(name)"], !value.isEmpty {
            return value
        }
        if let value = env["PETZINHO_\(name)"], !value.isEmpty {
            return value
        }
        #endif
        return nil
    }
}
