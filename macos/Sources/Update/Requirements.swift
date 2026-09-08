import Darwin
import Foundation

enum Requirements {
    static func check(destination: URL = URL(fileURLWithPath: "/Applications/Breve.app")) throws {
        #if os(macOS)
        let arch = ProcessInfo.processInfo.environment["BREVE_TEST_ARCH"] ?? {
            var sysinfo = utsname()
            uname(&sysinfo)
            return withUnsafePointer(to: &sysinfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
            }
        }()
        if arch != "arm64" {
            throw UpdateError.installFailed("Apple Silicon is required.")
        }
        #endif
        try checkXcode()
        try checkXcodeGen()
        let parent = destination.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: parent.path) else {
            throw UpdateError.destinationNotWritable(destination.path)
        }
    }

    static func checkXcode() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        process.arguments = ["-p"]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw UpdateError.missingXcode
        }
        let path = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard process.terminationStatus == 0, path.contains("Xcode.app") else {
            throw UpdateError.missingXcode
        }
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/xcodebuild") else {
            throw UpdateError.missingXcode
        }
    }

    static func checkXcodeGen() throws {
        let candidates = [
            "/opt/homebrew/bin/xcodegen",
            "/usr/local/bin/xcodegen",
        ]
        if candidates.contains(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["xcodegen"]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let found = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard process.terminationStatus == 0, !found.isEmpty else {
            throw UpdateError.missingXcodeGen
        }
    }
}
