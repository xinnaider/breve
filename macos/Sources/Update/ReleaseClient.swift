import CryptoKit
import Foundation

struct ReleaseClient: @unchecked Sendable {
    var session: URLSession
    var latestURL: URL
    var userAgent: String

    init(
        session: URLSession = ReleaseClient.makeSession(),
        latestURL: URL = UpdateURLs.latestRelease,
        userAgent: String = "Breve/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0") (dev.fordevs.breve)"
    ) {
        self.session = session
        self.latestURL = latestURL
        self.userAgent = userAgent
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpAdditionalHeaders = ["Accept": "application/vnd.github+json"]
        return URLSession(configuration: config, delegate: RedirectAllowlist(), delegateQueue: nil)
    }

    func fetchLatest() async throws -> PublishedRelease {
        var request = URLRequest(url: latestURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        try PublishedRelease.validateOrigin(latestURL)
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw UpdateError.network("GitHub HTTP \(http.statusCode).")
        }
        return try PublishedRelease.parse(data)
    }

    func downloadTarball(_ release: PublishedRelease, to file: URL) async throws -> String {
        try PublishedRelease.validateOrigin(release.tarballURL)
        var request = URLRequest(url: release.tarballURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (temp, response) = try await session.download(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw UpdateError.network("Tarball HTTP \(http.statusCode).")
        }
        if FileManager.default.fileExists(atPath: file.path) {
            try FileManager.default.removeItem(at: file)
        }
        try FileManager.default.moveItem(at: temp, to: file)
        return try Self.sha256(file)
    }

    static func sha256(_ file: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: 1024 * 1024)
            if chunk.isEmpty { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

final class RedirectAllowlist: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let url = request.url else { return nil }
        do {
            try PublishedRelease.validateOrigin(url)
            return request
        } catch {
            return nil
        }
    }
}
