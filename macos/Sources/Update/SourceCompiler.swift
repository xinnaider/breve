import Foundation

struct CompiledUpdate: Sendable {
    let root: URL
    let app: URL
    let release: PublishedRelease
    let sha256: String
}

struct SourceCompiler: @unchecked Sendable {
    var fileManager: FileManager = .default
    var cacheRoot: URL
    var environment: [String: String]
    var extraPath: String

    init(
        cacheRoot: URL = SourceCompiler.defaultCache,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        extraPath: String = "/opt/homebrew/bin:/usr/local/bin"
    ) {
        self.cacheRoot = cacheRoot
        self.environment = environment
        self.extraPath = extraPath
    }

    static var defaultCache: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches")
        return caches.appendingPathComponent("dev.fordevs.breve/build.noindex", isDirectory: true)
    }

    func extract(archive: URL, release: PublishedRelease) throws -> URL {
        let work = cacheRoot.appendingPathComponent(release.marketingVersion, isDirectory: true)
        if fileManager.fileExists(atPath: work.path) {
            try fileManager.removeItem(at: work)
        }
        try fileManager.createDirectory(at: work, withIntermediateDirectories: true)
        try run("/usr/bin/tar", ["-xzf", archive.path, "-C", work.path])
        let children = try fileManager.contentsOfDirectory(at: work, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                    && !url.lastPathComponent.hasPrefix(".")
                    && url.lastPathComponent != "src.tar.gz"
            }
        guard let root = children.first(where: { fileManager.fileExists(atPath: $0.appendingPathComponent("build.sh").path) })
                ?? children.first
        else {
            throw UpdateError.installFailed("The source archive had no project root.")
        }
        try SourceTree.requireMarketing(root, expected: release.marketingVersion)
        return root
    }

    func compile(root: URL, expectedVersion: String, onLine: (@Sendable (String) -> Void)? = nil) throws -> URL {
        try SourceTree.requireMarketing(root, expected: expectedVersion)
        let script = root.appendingPathComponent("build.sh")
        guard fileManager.isReadableFile(atPath: script.path) else {
            throw UpdateError.installFailed("build.sh is missing from the tagged source.")
        }
        var env = environment
        let path = env["PATH"] ?? "/usr/bin:/bin"
        env["PATH"] = "\(extraPath):\(path)"
        env["BREVE_QUIET"] = "1"
        try run("/bin/bash", [script.path], directory: root, environment: env)
        onLine?("build.sh finished")
        let app = root.appendingPathComponent("app/Breve.app")
        guard fileManager.fileExists(atPath: app.path) else {
            throw UpdateError.installFailed("build.sh did not produce app/Breve.app.")
        }
        return app
    }

    private func run(
        _ launch: String,
        _ arguments: [String],
        directory: URL? = nil,
        environment: [String: String]? = nil
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launch)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = environment
        // A file cannot fill a pipe buffer while waitUntilExit blocks.
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("breve-build-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let log = try FileHandle(forUpdating: logURL)
        defer {
            try? log.close()
            try? FileManager.default.removeItem(at: logURL)
        }
        process.standardOutput = log
        process.standardError = log
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw UpdateError.installFailed(error.localizedDescription)
        }
        let length = try log.seekToEnd()
        try log.seek(toOffset: length > 4096 ? length - 4096 : 0)
        let errText = String(data: try log.readToEnd() ?? Data(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            let snippet = errText.trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = snippet.isEmpty ? "" : ": \(snippet.suffix(400))"
            throw UpdateError.installFailed("Command failed: \(launch) (\(process.terminationStatus))\(suffix)")
        }
    }
}
