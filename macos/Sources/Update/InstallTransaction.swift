import Foundation

struct InstallTransaction {
    var fileManager: FileManager = .default

    func apply(source: URL, destination: URL) throws {
        guard fileManager.fileExists(atPath: source.path) else {
            throw UpdateError.installFailed("Compiled bundle is missing.")
        }
        let parent = destination.deletingLastPathComponent()
        guard fileManager.isWritableFile(atPath: parent.path) else {
            throw UpdateError.destinationNotWritable(destination.path)
        }
        if fileManager.fileExists(atPath: destination.path), !fileManager.isWritableFile(atPath: destination.path) {
            throw UpdateError.destinationNotWritable(destination.path)
        }

        let stamp = String(Int(Date().timeIntervalSince1970))
        let staging = URL(fileURLWithPath: destination.path + ".incoming.\(stamp)")
        let backup = URL(fileURLWithPath: destination.path + ".backup.\(stamp)")
        try? fileManager.removeItem(at: staging)

        do {
            try ditto(from: source, to: staging)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.moveItem(at: destination, to: backup)
            }
            do {
                try fileManager.moveItem(at: staging, to: destination)
            } catch {
                if fileManager.fileExists(atPath: backup.path) {
                    try? fileManager.removeItem(at: destination)
                    do {
                        try fileManager.moveItem(at: backup, to: destination)
                    } catch {
                        throw UpdateError.rollbackFailed(error.localizedDescription)
                    }
                }
                throw UpdateError.installFailed(error.localizedDescription)
            }
            try? fileManager.removeItem(at: backup)
        } catch let error as UpdateError {
            try? fileManager.removeItem(at: staging)
            throw error
        } catch {
            try? fileManager.removeItem(at: staging)
            if fileManager.fileExists(atPath: backup.path), !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.moveItem(at: backup, to: destination)
            }
            throw UpdateError.installFailed(error.localizedDescription)
        }
    }

    private func ditto(from: URL, to: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = [from.path, to.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw UpdateError.installFailed(error.localizedDescription)
        }
        guard process.terminationStatus == 0 else {
            throw UpdateError.installFailed("ditto failed.")
        }
    }
}
