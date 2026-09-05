import AppKit
import SwiftUI

@MainActor
final class SetupWindowController: NSObject, NSWindowDelegate {
    static let shared = SetupWindowController()

    private var window: NSWindow?
    private var hosting: NSHostingController<SetupRoot>?

    func show() {
        if window == nil {
            let root = SetupRoot(session: Session.shared)
            let controller = NSHostingController(rootView: root)
            controller.view.appearance = NSAppearance(named: .darkAqua)

            let window = NSWindow(contentViewController: controller)
            window.title = "Breve"
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(srgbRed: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
            window.appearance = NSAppearance(named: .darkAqua)
            window.level = .floating
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.setContentSize(NSSize(width: 560, height: 610))
            window.center()
            self.window = window
            self.hosting = controller
        }
        hosting?.rootView = SetupRoot(session: Session.shared)
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    func fitContent(height: CGFloat) {
        guard height > 0, let window else { return }
        let content = NSRect(x: 0, y: 0, width: 560, height: ceil(height))
        let size = window.frameRect(forContentRect: content).size
        guard abs(window.frame.height - size.height) > 1 else { return }
        // Keep the header in place when the next step needs a different height.
        var frame = window.frame
        frame.origin.y = frame.maxY - size.height
        frame.size = size
        if let screen = window.screen, frame.minY < screen.visibleFrame.minY {
            frame.origin.y = screen.visibleFrame.minY
        }
        window.setFrame(frame, display: true)
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            Session.shared.handleSetupClosed()
        }
    }
}
