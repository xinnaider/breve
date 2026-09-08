import Foundation

enum UpdateHelper {
    static var supportDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return support.appendingPathComponent("dev.fordevs.breve/helper", isDirectory: true)
    }

    static var logURL: URL {
        supportDirectory.deletingLastPathComponent().appendingPathComponent("update.log")
    }

    static func stage(from bundle: Bundle = .main) throws -> URL {
        let files = ["apply-update.sh", "install-app.sh", "with-lock.py"]
        let dest = supportDirectory
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        for name in files {
            guard let source = bundle.url(forResource: name, withExtension: nil)
                ?? bundle.url(forResource: (name as NSString).deletingPathExtension, withExtension: (name as NSString).pathExtension)
            else {
                throw UpdateError.installFailed("Helper \(name) is missing from the app bundle.")
            }
            let target = dest.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.copyItem(at: source, to: target)
        }
        return dest.appendingPathComponent("apply-update.sh")
    }

    static func launchDetached(
        script: URL,
        source: URL,
        destination: URL,
        pid: Int32,
        lock: URL = UpdateLock.standard.url
    ) throws {
        try FileManager.default.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }
        let log = try FileHandle(forWritingTo: logURL)
        try log.seekToEnd()

        var env = ProcessInfo.processInfo.environment
        env["BREVE_SRC"] = source.path
        env["BREVE_DEST"] = destination.path
        env["BREVE_PID"] = String(pid)
        env["BREVE_LOCK"] = lock.path
        env["BREVE_WAIT_SECS"] = "90"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/bash", script.path]
        process.environment = env
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        process.qualityOfService = .userInitiated
        do {
            try process.run()
        } catch {
            throw UpdateError.installFailed(error.localizedDescription)
        }
    }
}
