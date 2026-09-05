import AppKit
import SwiftUI

struct HitFlags: OptionSet, Sendable {
    let rawValue: Int
    static let click = HitFlags(rawValue: 1)
    static let solid = HitFlags(rawValue: 2)
}

extension View {
    func pointerHand(enabled: Bool = true) -> some View {
        modifier(PointerHand(enabled: enabled))
    }

    func hitRegion(_ id: String, _ flags: HitFlags = .click) -> some View {
        background {
            HitRegionProbe(id: id, flags: flags)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }
}

private struct PointerHand: ViewModifier {
    var enabled: Bool
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .onHover { on in
                guard enabled else { return }
                hovering = on
                if on {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .onChange(of: enabled) { _, on in
                if !on, hovering {
                    NSCursor.arrow.set()
                }
            }
    }
}

private struct HitRegionProbe: NSViewRepresentable {
    var id: String
    var flags: HitFlags

    func makeNSView(context: Context) -> HitProbeView {
        let view = HitProbeView()
        view.regionId = id
        view.flags = flags
        return view
    }

    func updateNSView(_ view: HitProbeView, context: Context) {
        let oldId = view.regionId
        view.regionId = id
        view.flags = flags
        if oldId != id {
            WidgetPanelController.shared.clearHit(id: oldId)
        }
        view.publish()
    }

    static func dismantleNSView(_ view: HitProbeView, coordinator: ()) {
        WidgetPanelController.shared.clearHit(id: view.regionId)
    }
}

final class HitProbeView: NSView {
    var regionId = ""
    var flags: HitFlags = .click

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func layout() {
        super.layout()
        publish()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        publish()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        publish()
    }

    func publish() {
        guard !regionId.isEmpty, window != nil, bounds.width > 1, bounds.height > 1 else { return }
        let id = regionId
        let flags = flags
        let rect = convert(bounds, to: nil)
        MainActor.assumeIsolated {
            WidgetPanelController.shared.setHit(id: id, flags: flags, rect: rect)
        }
    }
}
