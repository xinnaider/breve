import AppKit
import CoreGraphics
import SwiftUI

@MainActor
final class WidgetPanelController {
    static let shared = WidgetPanelController()

    private var panel: OverlayPanel?
    private var hosting: TrackingHost?
    private var observing = false
    private var contentSize = CGSize(width: Theme.face + 16, height: Theme.face + 28)
    private var frontObservers: [NSObjectProtocol] = []
    private var frontTimer: Timer?
    private var livePetOrigin: NSPoint?
    private var drag: PetDrag?
    private var dragMonitor: Any?
    private var cursorLocal: Any?
    private var cursorGlobal: Any?
    private var freezePanelSize: CGSize?
    private var closeHoldTask: Task<Void, Never>?
    private var clickHits: [String: CGRect] = [:]
    private var solidHits: [String: CGRect] = [:]

    private struct PetDrag {
        var grab: NSPoint
        var origin: NSPoint
        var moved = false
    }

    var isDragging: Bool { drag != nil }

    private static var overlayLevel: NSWindow.Level {
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)))
    }

    func start() {
        let root = WidgetRoot(session: Session.shared)
        let view = TrackingHost(rootView: root)
        view.sizingOptions = [.intrinsicContentSize]
        view.clipsToBounds = false
        view.wantsLayer = true
        view.layer?.masksToBounds = false

        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: Theme.face + 16, height: Theme.face + 16),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = Self.overlayLevel
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isExcludedFromWindowsMenu = true
        panel.contentView = view
        panel.animationBehavior = .none
        panel.sharingType = .none
        panel.worksWhenModal = true

        self.panel = panel
        self.hosting = view
        observe()
        watchFront()
        watchCursor()
        refresh()
    }

    func refresh() {
        layout(animated: false)
        bringForward()
    }

    func adoptContentSize(_ size: CGSize) {
        guard size.width > 8, size.height > 8 else { return }
        let session = Session.shared
        var next = size
        if session.bubbleOpen, let card = session.currentCard {
            let headline = session.tipKind == .info ? card.verso : card.frente
            let estimated = Theme.estimatedPanelSize(
                card: card,
                deep: session.bubbleDeep || session.quizPick != nil,
                edge: session.dock.edge,
                headline: headline,
                quizVisible: session.tipKind == .quiz
            )
            if session.bubbleDeep || session.quizPick != nil {
                next = CGSize(
                    width: max(size.width, estimated.width),
                    height: max(size.height, estimated.height)
                )
            }
        }
        let delta = hypot(next.width - contentSize.width, next.height - contentSize.height)
        if delta < 0.5 { return }
        contentSize = next
        if freezePanelSize != nil, next.width + 8 < (freezePanelSize?.width ?? 0) {
            return
        }
        layout(animated: false)
    }

    func holdSizeForClose() {
        freezePanelSize = contentSize.width > 8 ? contentSize : nil
        closeHoldTask?.cancel()
        closeHoldTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            freezePanelSize = nil
            layout(animated: false)
        }
    }

    func cancelCloseHold() {
        closeHoldTask?.cancel()
        closeHoldTask = nil
        freezePanelSize = nil
    }

    func prepareExpansion(card: Card) {
        let headline = Session.shared.tipKind == .info ? card.verso : card.frente
        let estimated = Theme.estimatedPanelSize(
            card: card,
            deep: true,
            edge: Session.shared.dock.edge,
            headline: headline,
            quizVisible: Session.shared.tipKind == .quiz
        )
        contentSize = CGSize(
            width: max(contentSize.width, estimated.width),
            height: max(contentSize.height, estimated.height)
        )
        layout(animated: false)
        bringForward()
    }

    private func watchCursor() {
        guard cursorLocal == nil else { return }
        let types: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .leftMouseUp]
        cursorLocal = NSEvent.addLocalMonitorForEvents(matching: types) { event in
            WidgetPanelController.shared.syncCursor()
            return event
        }
        cursorGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            WidgetPanelController.shared.syncCursor()
        }
    }

    func setHit(id: String, flags: HitFlags, rect: CGRect) {
        if flags.contains(.click) {
            clickHits[id] = rect
        } else {
            clickHits.removeValue(forKey: id)
        }
        if flags.contains(.solid) {
            solidHits[id] = rect
        } else {
            solidHits.removeValue(forKey: id)
        }
        syncCursor()
    }

    func clearHit(id: String) {
        clickHits.removeValue(forKey: id)
        solidHits.removeValue(forKey: id)
    }

    func syncCursor() {
        guard let panel, Session.shared.widgetVisible, panel.isVisible else { return }
        let point = panel.convertPoint(fromScreen: NSEvent.mouseLocation)
        let solid = isDragging || overSolid(point)
        Session.shared.setPointerInside(solid && !isDragging)
        if isDragging { return }
        guard solid else { return }
        if overClick(point) {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    func acceptsMouse(atWindow point: NSPoint) -> Bool {
        isDragging || overSolid(point)
    }

    private func overClick(_ point: NSPoint) -> Bool {
        clickHits.values.contains { $0.insetBy(dx: -2, dy: -2).contains(point) }
    }

    private func overSolid(_ point: NSPoint) -> Bool {
        if solidHits.values.contains(where: { $0.insetBy(dx: -2, dy: -2).contains(point) }) {
            return true
        }
        if overClick(point) { return true }
        guard let panel else { return false }
        let pet = Session.shared.dock.petRectInPanel(size: panel.frame.size).insetBy(dx: -10, dy: -10)
        if pet.contains(point) { return true }
        return clusterRect(in: panel).insetBy(dx: -4, dy: -4).contains(point)
    }

    private func clusterRect(in panel: NSPanel) -> NSRect {
        let size = panel.frame.size
        let cluster = CGSize(
            width: max(contentSize.width, Theme.face + 16),
            height: max(contentSize.height, Theme.face + 16)
        )
        switch Session.shared.dock.edge {
        case .right:
            return NSRect(
                x: size.width - cluster.width,
                y: size.height - cluster.height,
                width: cluster.width,
                height: cluster.height
            )
        case .left:
            return NSRect(
                x: 0,
                y: size.height - cluster.height,
                width: cluster.width,
                height: cluster.height
            )
        case .top:
            return NSRect(
                x: (size.width - cluster.width) / 2,
                y: size.height - cluster.height,
                width: cluster.width,
                height: cluster.height
            )
        case .bottom:
            return NSRect(
                x: (size.width - cluster.width) / 2,
                y: 0,
                width: cluster.width,
                height: cluster.height
            )
        }
    }

    func bringForward() {
        guard let panel, Session.shared.widgetVisible else { return }
        panel.level = Self.overlayLevel
        panel.orderFrontRegardless()
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    }

    func handlePanelEvent(_ event: NSEvent) -> Bool {
        switch event.type {
        case .leftMouseDown:
            if hitsControl(event.locationInWindow) { return false }
            guard petContains(event) else { return false }
            beginDrag(event)
            return true
        case .rightMouseDown:
            if hitsControl(event.locationInWindow) { return false }
            guard petContains(event) else { return false }
            showPetMenu(event)
            return true
        default:
            return false
        }
    }

    private func hitsControl(_ point: NSPoint) -> Bool {
        clickHits.contains { id, rect in
            id != "pet" && rect.insetBy(dx: -4, dy: -4).contains(point)
        }
    }

    private func showPetMenu(_ event: NSEvent) {
        guard let panel, let view = panel.contentView else { return }
        let session = Session.shared
        let menu = NSMenu()
        menu.autoenablesItems = false

        let swap = NSMenuItem(title: session.t("menu.swap"), action: #selector(PetMenuTarget.swap), keyEquivalent: "")
        swap.target = PetMenuTarget.shared
        swap.isEnabled = session.bootstrapped
        menu.addItem(swap)

        let settings = NSMenuItem(title: session.t("menu.settings"), action: #selector(PetMenuTarget.settings), keyEquivalent: "")
        settings.target = PetMenuTarget.shared
        menu.addItem(settings)

        let update = NSMenuItem(
            title: AppUpdater.shared.menuTitle(t: { session.t($0) }),
            action: #selector(PetMenuTarget.update),
            keyEquivalent: ""
        )
        update.target = PetMenuTarget.shared
        update.isEnabled = AppUpdater.shared.canCheck
        menu.addItem(update)

        menu.addItem(.separator())

        let pt = NSMenuItem(title: session.t("lang.pt"), action: #selector(PetMenuTarget.langPT), keyEquivalent: "")
        pt.target = PetMenuTarget.shared
        pt.state = session.language == .pt ? .on : .off
        menu.addItem(pt)

        let en = NSMenuItem(title: session.t("lang.en"), action: #selector(PetMenuTarget.langEN), keyEquivalent: "")
        en.target = PetMenuTarget.shared
        en.state = session.language == .en ? .on : .off
        menu.addItem(en)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: session.t("menu.quit"), action: #selector(PetMenuTarget.quit), keyEquivalent: "")
        quit.target = PetMenuTarget.shared
        menu.addItem(quit)

        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    private func beginDrag(_ event: NSEvent) {
        let pet = petScreenRect()
        let mouse = NSEvent.mouseLocation
        drag = PetDrag(
            grab: NSPoint(x: mouse.x - pet.origin.x, y: mouse.y - pet.origin.y),
            origin: pet.origin,
            moved: false
        )
        livePetOrigin = pet.origin
        if let dragMonitor {
            NSEvent.removeMonitor(dragMonitor)
        }
        dragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { event in
            MainActor.assumeIsolated {
                WidgetPanelController.shared.continueDrag(event)
            }
            return nil
        }
    }

    private func continueDrag(_ event: NSEvent) {
        guard var drag else { return }
        switch event.type {
        case .leftMouseDragged:
            let mouse = NSEvent.mouseLocation
            let next = NSPoint(x: mouse.x - drag.grab.x, y: mouse.y - drag.grab.y)
            if !drag.moved {
                let dx = next.x - drag.origin.x
                let dy = next.y - drag.origin.y
                if hypot(dx, dy) >= 6 {
                    drag.moved = true
                    self.drag = drag
                    NSCursor.closedHand.push()
                    let insets = Theme.clusterInsets(for: Session.shared.dock.edge)
                    contentSize = NSSize(
                        width: Theme.face + insets.leading + insets.trailing,
                        height: Theme.face + insets.top + insets.bottom
                    )
                    if Session.shared.bubbleOpen {
                        Session.shared.closeBubble()
                    }
                }
            }
            livePetOrigin = next
            layout()
        case .leftMouseUp:
            finishDrag()
        default:
            break
        }
    }

    private func finishDrag() {
        if let dragMonitor {
            NSEvent.removeMonitor(dragMonitor)
            self.dragMonitor = nil
        }
        let didMove = drag?.moved == true
        if didMove {
            NSCursor.pop()
        }
        drag = nil

        if didMove, let live = livePetOrigin {
            let screen = screen(for: NSEvent.mouseLocation)
            let visible = screen.visibleFrame
            let snapped = DockAnchor.snap(petOrigin: live, visible: visible)
            livePetOrigin = nil
            Session.shared.setDock(snapped)
        } else {
            livePetOrigin = nil
            layout()
            Session.shared.toggleBubble()
        }
    }

    private func petContains(_ event: NSEvent) -> Bool {
        guard let panel else { return false }
        let local = event.locationInWindow
        let pet = Session.shared.dock.petRectInPanel(size: panel.frame.size).insetBy(dx: -10, dy: -10)
        return pet.contains(local)
    }

    private func observe() {
        guard !observing else { return }
        observing = true
        track()
    }

    private func track() {
        let session = Session.shared
        withObservationTracking {
            _ = session.widgetVisible
            _ = session.bubbleOpen
            _ = session.bubbleDeep
            _ = session.currentCard
            _ = session.tipKind
            _ = session.quizPick
            _ = session.quizOptions
            _ = session.dock
            _ = session.language
            _ = session.catalog.cards.count
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.track()
                guard !self.isDragging else { return }
                self.layout(animated: false)
                self.bringForward()
            }
        }
    }

    private func watchFront() {
        let workspace = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didDeactivateApplicationNotification,
            NSWorkspace.activeSpaceDidChangeNotification
        ]
        for name in names {
            frontObservers.append(
                workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor in
                        self?.bringForward()
                    }
                }
            )
        }

        let local = NotificationCenter.default
        let appNames: [NSNotification.Name] = [
            NSApplication.didChangeScreenParametersNotification,
            NSApplication.didBecomeActiveNotification,
            NSApplication.didUnhideNotification,
            NSWindow.didChangeOcclusionStateNotification
        ]
        for name in appNames {
            frontObservers.append(
                local.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor in
                        self?.refresh()
                    }
                }
            )
        }

        frontTimer?.invalidate()
        let timer = Timer(timeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.bringForward()
            }
        }
        timer.tolerance = 0.3
        RunLoop.main.add(timer, forMode: .common)
        frontTimer = timer
    }

    private func layout(animated: Bool = false) {
        guard let panel else { return }
        let session = Session.shared
        if !session.widgetVisible {
            panel.orderOut(nil)
            return
        }

        let pet = petScreenRect()
        let size = panelSize(session: session)
        var frame = session.dock.panelFrame(size: size, pet: pet)
        if let livePetOrigin {
            frame = session.dock.panelFrame(
                size: size,
                pet: NSRect(origin: livePetOrigin, size: CGSize(width: Theme.face, height: Theme.face))
            )
        }

        panel.alphaValue = 1
        panel.level = Self.overlayLevel
        if panel.frame.equalTo(frame) {
            panel.orderFrontRegardless()
            return
        }
        let shouldAnimate = animated && !isDragging && panel.isVisible
        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.24
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
                ctx.allowsImplicitAnimation = true
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
    }

    private func petScreenRect() -> NSRect {
        if let livePetOrigin {
            return NSRect(origin: livePetOrigin, size: CGSize(width: Theme.face, height: Theme.face))
        }
        let visible = screen(forPet: Session.shared.dock).visibleFrame
        return Session.shared.dock.petRect(in: visible)
    }

    private func screen(forPet dock: DockAnchor) -> NSScreen {
        let screens = NSScreen.screens
        guard let main = NSScreen.main ?? screens.first else {
            preconditionFailure("macOS always has a screen")
        }
        let guess = dock.petRect(in: main.visibleFrame)
        let center = NSPoint(x: guess.midX, y: guess.midY)
        return screens.first { $0.frame.insetBy(dx: -40, dy: -40).contains(center) } ?? main
    }

    private func screen(for point: NSPoint) -> NSScreen {
        NSScreen.screens.first { $0.frame.contains(point) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func panelSize(session: Session) -> NSSize {
        let insets = Theme.clusterInsets(for: session.dock.edge)
        let pebble = NSSize(
            width: Theme.face + insets.leading + insets.trailing,
            height: Theme.face + insets.top + insets.bottom
        )
        if let freeze = freezePanelSize, !session.bubbleOpen {
            return NSSize(
                width: max(freeze.width, pebble.width),
                height: max(freeze.height, pebble.height)
            )
        }
        if session.bubbleOpen, let card = session.currentCard {
            let headline = session.tipKind == .info ? card.verso : card.frente
            let estimated = Theme.estimatedPanelSize(
                card: card,
                deep: session.bubbleDeep || session.quizPick != nil,
                edge: session.dock.edge,
                headline: headline,
                quizVisible: session.tipKind == .quiz
            )
            let visible = screen(forPet: session.dock).visibleFrame
            return NSSize(
                width: min(visible.width - 16, max(contentSize.width, estimated.width, pebble.width)),
                height: min(visible.height - 24, max(contentSize.height, estimated.height, pebble.height))
            )
        }
        if contentSize.width > 8 {
            return NSSize(
                width: max(contentSize.width, pebble.width),
                height: max(contentSize.height, pebble.height)
            )
        }
        return pebble
    }
}

@MainActor
private final class PetMenuTarget: NSObject {
    static let shared = PetMenuTarget()

    @objc func swap() {
        Session.shared.forceTip()
    }

    @objc func settings() {
        Session.shared.openSetup()
    }

    @objc func update() {
        let updater = AppUpdater.shared
        if case .available = updater.status {
            updater.present()
        } else {
            updater.probe()
        }
    }

    @objc func langPT() {
        Session.shared.setLanguage(.pt)
    }

    @objc func langEN() {
        Session.shared.setLanguage(.en)
    }

    @objc func quit() {
        Session.shared.quit()
    }
}

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        let consumed = MainActor.assumeIsolated {
            WidgetPanelController.shared.handlePanelEvent(event)
        }
        if consumed { return }
        super.sendEvent(event)
    }
}

private final class TrackingHost: NSHostingView<WidgetRoot> {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        window?.disableCursorRects()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let windowPoint = convert(point, to: nil)
        let accepted = MainActor.assumeIsolated {
            WidgetPanelController.shared.acceptsMouse(atWindow: windowPoint)
        }
        return accepted ? super.hitTest(point) : nil
    }
}
