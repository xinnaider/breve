import Foundation

enum UpdateError: Error, Equatable, LocalizedError {
    case busy
    case invalidRelease
    case prerelease
    case disallowedURL(String)
    case versionMismatch(expected: String, found: String)
    case bundleIdentifier(found: String)
    case missingExecutable
    case signature
    case destinationNotWritable(String)
    case missingXcode
    case missingXcodeGen
    case timeout
    case installFailed(String)
    case rollbackFailed(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .busy:
            "An update is already running."
        case .invalidRelease:
            "The published release could not be read."
        case .prerelease:
            "The latest GitHub item is a prerelease, not a stable tag."
        case .disallowedURL(let url):
            "Refusing to download from \(url)."
        case .versionMismatch(let expected, let found):
            "Bundle version \(found) does not match published \(expected)."
        case .bundleIdentifier(let found):
            "Bundle id \(found) is not dev.fordevs.breve."
        case .missingExecutable:
            "The compiled app has no executable."
        case .signature:
            "The compiled app is not a local ad-hoc build."
        case .destinationNotWritable(let path):
            "Cannot write \(path). No sudo will be attempted."
        case .missingXcode:
            "Xcode is required (xcode-select must point at Xcode.app)."
        case .missingXcodeGen:
            "XcodeGen is required (brew install xcodegen)."
        case .timeout:
            "The running app did not exit in time. The installed copy was left unchanged."
        case .installFailed(let message), .rollbackFailed(let message), .network(let message):
            message
        }
    }
}
