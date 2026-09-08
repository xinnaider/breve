import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppUpdater {
    static let shared = AppUpdater()

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, build: String)
        case compiling(version: String)
        case applying
        case error(String)
    }

    private(set) var status: Status = .idle
    private(set) var canCheck = true
    let currentVersion: String
    let currentBuild: String

    var destination: URL
    var client: ReleaseClient
    var compiler: SourceCompiler
    private var found: PublishedRelease?
    private var work: Task<Void, Never>?
    private let progress = UpdateProgressWindow()

    init(
        bundle: Bundle = .main,
        destination: URL = AppUpdater.defaultDestination,
        client: ReleaseClient = ReleaseClient(),
        compiler: SourceCompiler = SourceCompiler()
    ) {
        let info = bundle.infoDictionary
        currentVersion = info?["CFBundleShortVersionString"] as? String ?? "0"
        currentBuild = info?["CFBundleVersion"] as? String ?? "0"
        self.destination = destination
        self.client = client
        self.compiler = compiler
    }

    static var defaultDestination: URL {
        if let override = ProcessInfo.processInfo.environment["BREVE_DEST"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return URL(fileURLWithPath: "/Applications/Breve.app")
    }

    func start() {
        Task {
            await probe()
            if case .available = status {
                confirmInstall()
            }
        }
    }

    func probe() async {
        guard canStartCheck else { return }
        status = .checking
        refreshCanCheck()
        do {
            let release = try await client.fetchLatest()
            found = release
            if release.isNewer(than: currentVersion) {
                status = .available(version: release.marketingVersion, build: release.tag)
            } else {
                status = .upToDate
            }
        } catch {
            found = nil
            status = .error(Self.message(error))
        }
        refreshCanCheck()
    }

    func present() {
        switch status {
        case .compiling, .applying:
            progress.orderFront()
        case .available:
            confirmInstall()
        default:
            Task {
                await probe()
                if case .available = status {
                    confirmInstall()
                }
            }
        }
    }

    func menuTitle(t: (String) -> String) -> String {
        switch status {
        case .available:
            t("menu.update.available")
        case .error:
            t("menu.update.error")
        case .upToDate:
            t("menu.update.none")
        case .checking:
            t("setup.update.checking")
        case .compiling, .applying:
            t("setup.update.compiling")
        case .idle:
            t("menu.update")
        }
    }

    private var canStartCheck: Bool {
        switch status {
        case .checking, .compiling, .applying: false
        default: true
        }
    }

    private func refreshCanCheck() {
        switch status {
        case .checking, .compiling, .applying:
            canCheck = false
        default:
            canCheck = true
        }
    }

    private func confirmInstall() {
        guard case .available(let version, _) = status else { return }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = Session.shared.t("setup.update.confirm_title")
        alert.informativeText = Session.shared.t("setup.update.minutes", ["version": version])
        alert.addButton(withTitle: Session.shared.t("setup.update.action"))
        alert.addButton(withTitle: Session.shared.t("setup.update.later"))
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            beginCompile()
        }
        // Depois: status stays .available
    }

    private func beginCompile() {
        guard let release = found else { return }
        status = .compiling(version: release.marketingVersion)
        refreshCanCheck()
        progress.show(
            title: Session.shared.t("setup.update.progress_title"),
            detail: Session.shared.t("setup.update.progress_detail", ["version": release.marketingVersion])
        )
        work?.cancel()
        let dest = destination
        let compiler = compiler
        let client = client
        let labels: [String: String] = [
            "download": Session.shared.t("setup.update.progress_download"),
            "extract": Session.shared.t("setup.update.progress_extract"),
            "compile": Session.shared.t("setup.update.progress_compile"),
        ]
        work = Task.detached(priority: .userInitiated) {
            do {
                let app = try await UpdatePipeline.compilePublished(
                    release: release,
                    destination: dest,
                    client: client,
                    compiler: compiler,
                    onProgress: { stage in
                        let text = labels[stage] ?? stage
                        Task { @MainActor in
                            AppUpdater.shared.progress.setDetail(text)
                        }
                    }
                )
                await MainActor.run {
                    AppUpdater.shared.applyCompiled(app: app)
                }
            } catch {
                await MainActor.run {
                    AppUpdater.shared.fail(error)
                }
            }
        }
    }

    private func applyCompiled(app: URL) {
        status = .applying
        refreshCanCheck()
        progress.setDetail(Session.shared.t("setup.update.progress_apply"))
        do {
            let script = try UpdateHelper.stage()
            try UpdateHelper.launchDetached(
                script: script,
                source: app,
                destination: destination,
                pid: ProcessInfo.processInfo.processIdentifier
            )
            progress.close()
            NSApp.terminate(nil)
        } catch {
            fail(error)
        }
    }

    private func fail(_ error: Error) {
        progress.close()
        status = .error(Self.message(error))
        refreshCanCheck()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = Session.shared.t("setup.update.error_title")
        alert.informativeText = Self.message(error)
        alert.addButton(withTitle: Session.shared.t("setup.update.ok"))
        alert.runModal()
    }

    static func message(_ error: Error) -> String {
        let session = Session.shared
        guard let update = error as? UpdateError else {
            return error.localizedDescription
        }
        switch update {
        case .busy:
            return session.t("update.error.busy")
        case .invalidRelease:
            return session.t("update.error.invalid_release")
        case .prerelease:
            return session.t("update.error.prerelease")
        case .disallowedURL(let url):
            return session.t("update.error.origin", ["url": url])
        case .versionMismatch(let expected, let found):
            return session.t("update.error.version", ["expected": expected, "found": found])
        case .bundleIdentifier(let found):
            return session.t("update.error.bundle_id", ["found": found])
        case .missingExecutable:
            return session.t("update.error.executable")
        case .signature:
            return session.t("update.error.signature")
        case .destinationNotWritable(let path):
            return session.t("update.error.writable", ["path": path])
        case .missingXcode:
            return session.t("update.error.xcode")
        case .missingXcodeGen:
            return session.t("update.error.xcodegen")
        case .timeout:
            return session.t("update.error.timeout")
        case .installFailed(let message), .rollbackFailed(let message), .network(let message):
            return session.t("update.error.failed", ["message": message])
        }
    }
}

@MainActor
final class UpdateProgressWindow {
    private var window: NSPanel?
    private let detail = NSTextField(labelWithString: "")

    func show(title: String, detail: String) {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 140),
                styleMask: [.titled, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            panel.title = title
            panel.isReleasedWhenClosed = false
            panel.level = .floating
            let spinner = NSProgressIndicator(frame: NSRect(x: 20, y: 88, width: 18, height: 18))
            spinner.style = .spinning
            spinner.controlSize = .small
            spinner.startAnimation(nil)
            let label = NSTextField(labelWithString: "")
            label.frame = NSRect(x: 48, y: 86, width: 352, height: 20)
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.stringValue = title
            self.detail.frame = NSRect(x: 20, y: 20, width: 380, height: 56)
            self.detail.font = .systemFont(ofSize: 12)
            self.detail.textColor = .secondaryLabelColor
            self.detail.maximumNumberOfLines = 3
            self.detail.lineBreakMode = .byWordWrapping
            let content = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 140))
            content.addSubview(spinner)
            content.addSubview(label)
            content.addSubview(self.detail)
            panel.contentView = content
            window = panel
        }
        window?.title = title
        self.detail.stringValue = detail
        orderFront()
    }

    func setDetail(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        detail.stringValue = trimmed
    }

    func orderFront() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.orderOut(nil)
    }
}
