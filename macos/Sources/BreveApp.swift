import AppKit
import Sparkle
import SwiftUI

@main
struct BreveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            StatusMenu()
        } label: {
            Image(nsImage: StatusIcon.image)
                .renderingMode(.original)
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        let controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: AppUpdater.shared,
            userDriverDelegate: nil
        )
        updaterController = controller
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        WidgetPanelController.shared.start()
        Session.shared.start()
        WidgetPanelController.shared.refresh()
        updaterController?.startUpdater()
        if let updater = updaterController?.updater {
            AppUpdater.shared.attach(updater)
        }
        #if DEBUG
        if DebugEnv.value("SPARKLE_CHECK") == "1" {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                AppUpdater.shared.present()
            }
        }
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Session.shared.openSetup()
        return true
    }
}

private struct StatusMenu: View {
    @Bindable private var session = Session.shared
    @Bindable private var updater = AppUpdater.shared

    var body: some View {
        Button(session.t("menu.swap")) {
            session.forceTip()
        }
        .disabled(!session.bootstrapped)
        Button(session.t("menu.settings")) {
            session.openSetup()
        }
        .keyboardShortcut(",", modifiers: .command)
        Button(updater.menuTitle(t: { session.t($0) })) {
            updater.present()
        }
        .disabled(!updater.canCheck)
        Divider()
        Button(session.t("lang.pt")) {
            session.setLanguage(.pt)
        }
        Button(session.t("lang.en")) {
            session.setLanguage(.en)
        }
        Divider()
        Button(session.t("menu.quit")) {
            session.quit()
        }
    }
}

enum StatusIcon {
    static let image: NSImage = {
        let point = NSSize(width: 18, height: 18)
        let source = NSImage(named: "Bonequinho") ?? NSImage(size: point)
        let copy = source.copy() as? NSImage ?? source
        copy.size = point
        copy.isTemplate = false
        return copy
    }()
}
