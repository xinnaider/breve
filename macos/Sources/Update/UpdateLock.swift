import Darwin
import Foundation

struct UpdateLock: Sendable {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    static var standard: UpdateLock {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return UpdateLock(
            url: support
                .appendingPathComponent("dev.fordevs.breve", isDirectory: true)
                .appendingPathComponent("update.lock")
        )
    }

    func acquire() throws -> FileLock {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = open(url.path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else { throw UpdateError.installFailed("Could not open the update lock.") }
        if flock(fd, LOCK_EX | LOCK_NB) != 0 {
            close(fd)
            throw UpdateError.busy
        }
        return FileLock(fd: fd)
    }

    func withLock<T>(_ body: () throws -> T) throws -> T {
        let held = try acquire()
        defer { held.unlock() }
        return try body()
    }
}

final class FileLock: @unchecked Sendable {
    private var fd: Int32
    private var openFd: Bool

    init(fd: Int32) {
        self.fd = fd
        self.openFd = true
    }

    func unlock() {
        guard openFd else { return }
        _ = flock(fd, LOCK_UN)
        close(fd)
        openFd = false
    }

    deinit { unlock() }
}
