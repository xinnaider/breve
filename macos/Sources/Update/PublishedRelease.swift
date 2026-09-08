import Foundation

struct PublishedRelease: Equatable, Sendable {
    let id: Int
    let tag: String
    let marketingVersion: String
    let commitish: String
    let tarballURL: URL
    let htmlURL: URL

    static let expectedOwnerRepo = "xinnaider/breve"
    static let expectedBundleId = "dev.fordevs.breve"

    static func parse(_ data: Data) throws -> PublishedRelease {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else { throw UpdateError.invalidRelease }
        if json["draft"] as? Bool == true { throw UpdateError.invalidRelease }
        if json["prerelease"] as? Bool == true { throw UpdateError.prerelease }
        guard let id = json["id"] as? Int,
              let tag = json["tag_name"] as? String,
              VersionPolicy.isStableTag(tag),
              let tarball = json["tarball_url"] as? String,
              let tarballURL = URL(string: tarball),
              let html = json["html_url"] as? String,
              let htmlURL = URL(string: html)
        else { throw UpdateError.invalidRelease }
        try Self.validateOrigin(tarballURL)
        try Self.validateOrigin(htmlURL)
        let commitish = (json["target_commitish"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        return PublishedRelease(
            id: id,
            tag: tag,
            marketingVersion: VersionPolicy.tagToMarketing(tag),
            commitish: commitish,
            tarballURL: tarballURL,
            htmlURL: htmlURL
        )
    }

    static func validateOrigin(_ url: URL) throws {
        guard let host = url.host?.lowercased() else { throw UpdateError.disallowedURL(url.absoluteString) }
        let allowed = ["api.github.com", "codeload.github.com", "github.com"]
        guard allowed.contains(host) else { throw UpdateError.disallowedURL(url.absoluteString) }
        guard url.path.contains("/\(expectedOwnerRepo)") || url.path.contains("/\(expectedOwnerRepo)/")
            || url.path.hasPrefix("/repos/\(expectedOwnerRepo)")
        else {
            throw UpdateError.disallowedURL(url.absoluteString)
        }
        guard url.scheme == "https" else { throw UpdateError.disallowedURL(url.absoluteString) }
    }

    func isNewer(than installed: String) -> Bool {
        AppVersion(installed) < AppVersion(marketingVersion)
    }
}

enum UpdateURLs {
    static let latestRelease = URL(string: "https://api.github.com/repos/xinnaider/breve/releases/latest")!
}
