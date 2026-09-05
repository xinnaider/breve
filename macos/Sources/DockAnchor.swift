import AppKit
import Foundation

enum DockEdge: String, Sendable, CaseIterable {
    case left, right, top, bottom

    var isHorizontal: Bool {
        self == .left || self == .right
    }
}

struct DockAnchor: Equatable, Sendable {
    var edge: DockEdge
    var along: CGFloat

    static let fallback = DockAnchor(edge: .right, along: 0.78)

    func petRect(in visible: NSRect) -> NSRect {
        let face = Theme.face
        let inset = Theme.edge
        switch edge {
        case .right:
            let span = max(0, visible.height - 2 * inset - face)
            let y = visible.minY + inset + along * span
            return NSRect(x: visible.maxX - inset - face, y: y, width: face, height: face)
        case .left:
            let span = max(0, visible.height - 2 * inset - face)
            let y = visible.minY + inset + along * span
            return NSRect(x: visible.minX + inset, y: y, width: face, height: face)
        case .top:
            let span = max(0, visible.width - 2 * inset - face)
            let x = visible.minX + inset + along * span
            return NSRect(x: x, y: visible.maxY - inset - face, width: face, height: face)
        case .bottom:
            let span = max(0, visible.width - 2 * inset - face)
            let x = visible.minX + inset + along * span
            return NSRect(x: x, y: visible.minY + inset, width: face, height: face)
        }
    }

    static func snap(petOrigin: NSPoint, visible: NSRect) -> DockAnchor {
        let face = Theme.face
        let inset = Theme.edge
        let center = NSPoint(x: petOrigin.x + face / 2, y: petOrigin.y + face / 2)
        let dLeft = center.x - visible.minX
        let dRight = visible.maxX - center.x
        let dBottom = center.y - visible.minY
        let dTop = visible.maxY - center.y

        let edge: DockEdge
        if dRight <= dLeft, dRight <= dBottom, dRight <= dTop {
            edge = .right
        } else if dLeft <= dRight, dLeft <= dBottom, dLeft <= dTop {
            edge = .left
        } else if dTop <= dBottom {
            edge = .top
        } else {
            edge = .bottom
        }

        switch edge {
        case .left, .right:
            let span = max(0.0001, visible.height - 2 * inset - face)
            let along = (petOrigin.y - visible.minY - inset) / span
            return DockAnchor(edge: edge, along: min(1, max(0, along)))
        case .top, .bottom:
            let span = max(0.0001, visible.width - 2 * inset - face)
            let along = (petOrigin.x - visible.minX - inset) / span
            return DockAnchor(edge: edge, along: min(1, max(0, along)))
        }
    }

    func panelFrame(size: CGSize, pet: NSRect) -> NSRect {
        let inset = Theme.clusterInsets(for: edge)
        var frame = NSRect(origin: .zero, size: size)
        switch edge {
        case .right:
            frame.origin.x = pet.maxX + inset.trailing - size.width
            frame.origin.y = pet.maxY + inset.top - size.height
        case .left:
            frame.origin.x = pet.minX - inset.leading
            frame.origin.y = pet.maxY + inset.top - size.height
        case .top:
            frame.origin.x = pet.midX - size.width / 2
            frame.origin.y = pet.maxY + inset.top - size.height
        case .bottom:
            frame.origin.x = pet.midX - size.width / 2
            frame.origin.y = pet.minY - inset.bottom
        }
        return frame
    }

    func petRectInPanel(size: CGSize) -> NSRect {
        let face = Theme.face
        let inset = Theme.clusterInsets(for: edge)
        switch edge {
        case .right:
            return NSRect(
                x: size.width - inset.trailing - face,
                y: size.height - inset.top - face,
                width: face,
                height: face
            )
        case .left:
            return NSRect(
                x: inset.leading,
                y: size.height - inset.top - face,
                width: face,
                height: face
            )
        case .top:
            return NSRect(
                x: (size.width - face) / 2,
                y: size.height - inset.top - face,
                width: face,
                height: face
            )
        case .bottom:
            return NSRect(
                x: (size.width - face) / 2,
                y: inset.bottom,
                width: face,
                height: face
            )
        }
    }
}
