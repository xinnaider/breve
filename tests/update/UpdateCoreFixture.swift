import Foundation

@main
enum UpdateCoreFixture {
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

        check("1.0.2 < 1.0.3", AppVersion("1.0.2") < AppVersion("1.0.3"))
        check("v1.0.3 == 1.0.3", AppVersion("v1.0.3") == AppVersion("1.0.3"))
        check("igual não é menor", !(AppVersion("1.0.2") < AppVersion("1.0.2")))
        check("tag estável", VersionPolicy.isStableTag("v1.0.2"))
        check("tag main recusada", !VersionPolicy.isStableTag("main"))
        check("tag 1.0 recusada", !VersionPolicy.isStableTag("v1.0"))

        let good = """
        {"id":10,"tag_name":"v1.0.3","draft":false,"prerelease":false,\
        "tarball_url":"https://api.github.com/repos/xinnaider/breve/tarball/v1.0.3",\
        "html_url":"https://github.com/xinnaider/breve/releases/tag/v1.0.3",\
        "target_commitish":"deadbeef"}
        """.data(using: .utf8)!
        do {
            let release = try PublishedRelease.parse(good)
            check("parse marketing", release.marketingVersion == "1.0.3")
            check("parse newer", release.isNewer(than: "1.0.2"))
            check("parse not newer than self", !release.isNewer(than: "1.0.3"))
        } catch {
            check("parse marketing", false)
            check("parse newer", false)
            check("parse not newer than self", false)
        }

        let pre = """
        {"id":10,"tag_name":"v1.0.3","draft":false,"prerelease":true,\
        "tarball_url":"https://api.github.com/repos/xinnaider/breve/tarball/v1.0.3",\
        "html_url":"https://github.com/xinnaider/breve/releases/tag/v1.0.3"}
        """.data(using: .utf8)!
        check("prerelease", (try? PublishedRelease.parse(pre)) == nil)

        let evil = """
        {"id":10,"tag_name":"v1.0.3","draft":false,"prerelease":false,\
        "tarball_url":"https://evil.example/tarball",\
        "html_url":"https://github.com/xinnaider/breve/releases/tag/v1.0.3"}
        """.data(using: .utf8)!
        check("origem recusada", (try? PublishedRelease.parse(evil)) == nil)

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("breve-upd-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        let root = tmp.appendingPathComponent("src")
        try! FileManager.default.createDirectory(at: root.appendingPathComponent("macos"), withIntermediateDirectories: true)
        try! "MARKETING_VERSION: \"1.0.3\"\n".write(to: root.appendingPathComponent("macos/project.yml"), atomically: true, encoding: .utf8)
        check("SourceTree lê versão", (try? SourceTree.marketingVersion(atRoot: root)) == "1.0.3")
        var mismatch = false
        do {
            try SourceTree.requireMarketing(root, expected: "1.0.2")
        } catch UpdateError.versionMismatch(let expected, let found) {
            mismatch = expected == "1.0.2" && found == "1.0.3"
        } catch {
            mismatch = false
        }
        check("SourceTree mismatch", mismatch)

        // Regression: extraction must not delete the downloaded archive; verbose
        // builds must finish even after writing more than a pipe buffer.
        do {
            let cache = tmp.appendingPathComponent("cache")
            try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
            let script = "#!/bin/bash\nfor ((i=0;i<12000;i++)); do echo verbose-build-output; echo verbose-build-error >&2; done\nmkdir -p app/Breve.app\n"
            try script.write(to: root.appendingPathComponent("build.sh"), atomically: true, encoding: .utf8)
            let archive = cache.appendingPathComponent("download.tar.gz")
            let tar = Process()
            tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            tar.arguments = ["-czf", archive.path, "-C", tmp.path, "src"]
            try tar.run()
            tar.waitUntilExit()
            let compiler = SourceCompiler(cacheRoot: cache)
            let release = try PublishedRelease.parse(good)
            let extracted = try compiler.extract(archive: archive, release: release)
            check("extract preserves archive", FileManager.default.fileExists(atPath: archive.path))
            let built = try compiler.compile(root: extracted, expectedVersion: "1.0.3")
            check("verbose compile finishes", FileManager.default.fileExists(atPath: built.path))
        } catch {
            check("archive and verbose build regression", false)
            print(error)
        }

        let lockURL = tmp.appendingPathComponent("lock")
        let lock = UpdateLock(url: lockURL)
        let held = try! lock.acquire()
        var busy = false
        do {
            _ = try lock.acquire()
        } catch UpdateError.busy {
            busy = true
        } catch {
            busy = false
        }
        check("lock concorrente", busy)
        held.unlock()
        check("lock após unlock", (try? lock.acquire()) != nil)

        let dest = tmp.appendingPathComponent("Breve.app")
        let source = tmp.appendingPathComponent("New.app")
        try! FileManager.default.createDirectory(at: dest.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: source.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        try! "old".write(to: dest.appendingPathComponent("Contents/marker"), atomically: true, encoding: .utf8)
        try! "new".write(to: source.appendingPathComponent("Contents/marker"), atomically: true, encoding: .utf8)
        try! InstallTransaction().apply(source: source, destination: dest)
        let marker = try? String(contentsOf: dest.appendingPathComponent("Contents/marker"), encoding: .utf8)
        check("transação Swift", marker?.trimmingCharacters(in: .whitespacesAndNewlines) == "new")

        let fake = tmp.appendingPathComponent("Signed.app")
        let mac = fake.appendingPathComponent("Contents/MacOS")
        try! FileManager.default.createDirectory(at: mac, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": "dev.fordevs.breve",
            "CFBundleShortVersionString": "1.0.3",
            "CFBundleVersion": "4",
            "CFBundleExecutable": "Breve",
        ]
        (info as NSDictionary).write(to: fake.appendingPathComponent("Contents/Info.plist"), atomically: true)
        let binary = mac.appendingPathComponent("Breve")
        FileManager.default.createFile(atPath: binary.path, contents: Data("#!/bin/sh\n".utf8), attributes: [.posixPermissions: 0o755])
        let sign = Process()
        sign.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        sign.arguments = ["-s", "-", "-f", fake.path]
        sign.standardOutput = Pipe()
        sign.standardError = Pipe()
        try! sign.run()
        sign.waitUntilExit()
        do {
            let validated = try BundleValidator.inspect(fake, expectedVersion: "1.0.3")
            check("bundle id+versão+adhoc", validated.identifier == "dev.fordevs.breve" && validated.version == "1.0.3")
        } catch {
            check("bundle id+versão+adhoc", false)
            print("    \(error)")
        }

        let tampered = tmp.appendingPathComponent("Tampered.app")
        try! FileManager.default.copyItem(at: fake, to: tampered)
        try! Data("changed after signing".utf8).write(to: tampered.appendingPathComponent("Contents/MacOS/Breve"))
        check("tampered signature rejected", (try? BundleValidator.inspect(tampered, expectedVersion: "1.0.3")) == nil)

        var wrongId = false
        try! "CFBundleIdentifier".write(to: tmp.appendingPathComponent("noop"), atomically: true, encoding: .utf8)
        let badId = tmp.appendingPathComponent("BadId.app")
        try! FileManager.default.copyItem(at: fake, to: badId)
        let badInfo: [String: Any] = [
            "CFBundleIdentifier": "dev.fordevs.other",
            "CFBundleShortVersionString": "1.0.3",
            "CFBundleVersion": "4",
            "CFBundleExecutable": "Breve",
        ]
        (badInfo as NSDictionary).write(to: badId.appendingPathComponent("Contents/Info.plist"), atomically: true)
        do {
            _ = try BundleValidator.inspect(badId, expectedVersion: "1.0.3")
        } catch UpdateError.bundleIdentifier(let found) {
            wrongId = found == "dev.fordevs.other"
        } catch {
            wrongId = false
        }
        check("bundle id errado", wrongId)

        if failed > 0 {
            fputs("UpdateCoreFixture: \(failed) falha(s)\n", stderr)
            exit(1)
        }
        print("UpdateCoreFixture: ok")
    }
}
