import Foundation

enum UpdatePipeline {
    static func compilePublished(
        release: PublishedRelease,
        destination: URL,
        client: ReleaseClient,
        compiler: SourceCompiler,
        onProgress: @escaping @Sendable (String) -> Void
    ) async throws -> URL {
        let held = try UpdateLock.standard.acquire()
        defer { held.unlock() }
        try Requirements.check(destination: destination)
        // Keep the download outside the directory extract() replaces.
        let cacheRoot = compiler.cacheRoot
        try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        let archive = cacheRoot.appendingPathComponent("download-\(UUID().uuidString).tar.gz")
        defer { try? FileManager.default.removeItem(at: archive) }
        onProgress("download")
        _ = try await client.downloadTarball(release, to: archive)
        onProgress("extract")
        let root = try compiler.extract(archive: archive, release: release)
        onProgress("compile")
        let app = try compiler.compile(root: root, expectedVersion: release.marketingVersion)
        _ = try BundleValidator.inspect(app, expectedVersion: release.marketingVersion)
        return app
    }
}
