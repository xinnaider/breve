import Foundation

@main
enum MigrateConfigFixture {
    static func main() {
        var failed = 0
        func check(_ name: String, _ ok: Bool) {
            if ok {
                print("ok  \(name)")
            } else {
                print("FAIL \(name)")
                failed += 1
            }
        }

        let token = UUID().uuidString
        let currentName = "dev.fordevs.breve.fixture.current.\(token)"
        let legacyName = "dev.fordevs.breve.fixture.legacy.\(token)"
        let isolatedName = "dev.fordevs.breve.fixture.isolated.\(token)"
        let current = UserDefaults(suiteName: currentName)!
        let legacy = UserDefaults(suiteName: legacyName)!
        let isolated = UserDefaults(suiteName: isolatedName)!
        defer {
            for name in [currentName, legacyName, isolatedName] {
                UserDefaults.standard.removePersistentDomain(forName: name)
            }
        }

        let oldChoices = UserConfig(
            bootstrapped: true,
            sel: ["dev": .init(on: true, topics: ["solid", "dry"])],
            lastShownId: "sns-vs-sqs",
            dockEdge: "left",
            dockAlong: 0.42,
            learnQuiz: false,
            learnInfo: true,
            language: "en"
        )
        let newerChoices = UserConfig(
            bootstrapped: true,
            sel: ["dev": .init(on: true, topics: ["kiss"])],
            lastShownId: "newer-card",
            dockEdge: "right",
            dockAlong: 0.9,
            learnQuiz: true,
            learnInfo: false,
            language: "pt"
        )

        legacy.set(try! JSONEncoder().encode(oldChoices), forKey: UserConfig.legacyDefaultsKey)
        let migrated = UserConfig.load(from: current, legacy: legacy)
        check("migra legado para breve.config.v1", migrated == oldChoices)
        check("grava a chave nova após decode válido", decode(current.data(forKey: UserConfig.defaultsKey)) == oldChoices)
        check("não apaga o domínio legado", decode(legacy.data(forKey: UserConfig.legacyDefaultsKey)) == oldChoices)

        current.set(try! JSONEncoder().encode(newerChoices), forKey: UserConfig.defaultsKey)
        let winner = UserConfig.load(from: current, legacy: legacy)
        check("chave nova prevalece sobre o legado", winner == newerChoices)

        let skipped = UserConfig.load(from: isolated, legacy: nil)
        check("debug isolado não lê o domínio legado", skipped == nil)
        check("debug isolado não grava chave nova", isolated.data(forKey: UserConfig.defaultsKey) == nil)
        check("domínio legado intacto após isolado", decode(legacy.data(forKey: UserConfig.legacyDefaultsKey)) == oldChoices)

        if failed > 0 {
            fputs("MigrateConfigFixture: \(failed) falha(s)\n", stderr)
            exit(1)
        }
        print("MigrateConfigFixture: ok")
    }

    private static func decode(_ data: Data?) -> UserConfig? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(UserConfig.self, from: data)
    }
}
