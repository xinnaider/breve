import Foundation
import Observation
import Sparkle

@MainActor
@Observable
final class AppUpdater: NSObject, SPUUpdaterDelegate {
    static let shared = AppUpdater()

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, build: String)
        case error(String)
    }

    private(set) var status: Status = .idle
    private(set) var canCheck = false
    let currentVersion: String
    let currentBuild: String

    private var updater: SPUUpdater?
    private var canCheckObservation: NSKeyValueObservation?
    private var statusBeforeCycle: Status = .idle

    override init() {
        let info = Bundle.main.infoDictionary
        currentVersion = info?["CFBundleShortVersionString"] as? String ?? "0"
        currentBuild = info?["CFBundleVersion"] as? String ?? "0"
        super.init()
    }

    func attach(_ updater: SPUUpdater) {
        canCheckObservation?.invalidate()
        self.updater = updater
        updater.automaticallyDownloadsUpdates = false
        canCheckObservation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] _, change in
            guard let value = change.newValue else { return }
            Task { @MainActor in
                self?.canCheck = value
            }
        }
    }

    func probe() {
        guard let updater, updater.canCheckForUpdates else { return }
        beginCycle()
        updater.checkForUpdateInformation()
    }

    func present() {
        guard let updater, updater.canCheckForUpdates else { return }
        beginCycle()
        updater.checkForUpdates()
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
        case .idle:
            t("menu.update")
        }
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        status = .available(version: item.displayVersionString, build: item.versionString)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        status = .upToDate
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        applySparkleError(error, keepSelectionOnCancel: true)
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        canCheck = updater.canCheckForUpdates
        if let error {
            applySparkleError(error, keepSelectionOnCancel: true)
        } else if case .checking = status {
            status = .upToDate
        }
        _ = updateCheck
    }

    private func beginCycle() {
        statusBeforeCycle = status
        status = .checking
    }

    private func applySparkleError(_ error: Error, keepSelectionOnCancel: Bool) {
        let ns = error as NSError
        if ns.domain == SUSparkleErrorDomain {
            switch ns.code {
            case Int(SUError.noUpdateError.rawValue):
                status = .upToDate
            case Int(SUError.installationCanceledError.rawValue):
                if keepSelectionOnCancel, case .checking = status {
                    status = statusBeforeCycle
                }
            default:
                status = .error(ns.localizedDescription)
            }
            return
        }
        status = .error(ns.localizedDescription)
    }
}
