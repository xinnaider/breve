import Foundation

struct ValidatedBundle: Equatable, Sendable {
    let url: URL
    let identifier: String
    let version: String
    let build: String
}

enum BundleValidator {
    static func inspect(_ url: URL, expectedVersion: String, fileManager: FileManager = .default) throws -> ValidatedBundle {
        let infoURL = url.appendingPathComponent("Contents/Info.plist")
        guard let info = NSDictionary(contentsOf: infoURL) as? [String: Any] else {
            throw UpdateError.installFailed("Info.plist is missing.")
        }
        let identifier = info["CFBundleIdentifier"] as? String ?? ""
        guard identifier == PublishedRelease.expectedBundleId else {
            throw UpdateError.bundleIdentifier(found: identifier)
        }
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        guard AppVersion(version) == AppVersion(expectedVersion) else {
            throw UpdateError.versionMismatch(expected: expectedVersion, found: version)
        }
        let build = info["CFBundleVersion"] as? String ?? ""
        let executableName = info["CFBundleExecutable"] as? String ?? "Breve"
        let binary = url.appendingPathComponent("Contents/MacOS/\(executableName)")
        guard fileManager.isExecutableFile(atPath: binary.path) else {
            throw UpdateError.missingExecutable
        }
        try validateAdHocSignature(url)
        let verify = Process()
        verify.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        verify.arguments = ["--verify", "--deep", "--strict", url.path]
        verify.standardOutput = FileHandle.nullDevice
        verify.standardError = FileHandle.nullDevice
        try verify.run()
        verify.waitUntilExit()
        guard verify.terminationStatus == 0 else { throw UpdateError.signature }
        return ValidatedBundle(url: url, identifier: identifier, version: version, build: build)
    }

    static func validateAdHocSignature(_ url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-dv", url.path]
        let err = Pipe()
        process.standardError = err
        process.standardOutput = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw UpdateError.signature
        }
        let text = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let adHoc = text.contains("Signature=adhoc") || text.contains("flags=0x2(adhoc)") || text.contains("adhoc")
        guard process.terminationStatus == 0, adHoc else {
            throw UpdateError.signature
        }
    }
}
