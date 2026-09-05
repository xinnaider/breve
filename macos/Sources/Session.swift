import AppKit
import Foundation
import Observation
import os
import SwiftUI

@MainActor
@Observable
final class Session {
    static let shared = Session()
    private static let log = Logger(subsystem: "dev.fordevs.petzinho", category: "session")

    var catalog = Catalog(types: [], cards: [])
    var sel: [String: TypeSelection] = [:]
    var bootstrapped = false
    var lastShownId: String?
    var currentCard: Card?
    var loadError: String?

    var widgetVisible = false
    var bubbleOpen = false
    var bubbleDeep = false
    var dock = DockAnchor.fallback
    var setupVisible = false
    var setupPage: SetupPage = .learn
    var learnQuiz = true
    var learnInfo = true
    var tipKind: TipKind = .info
    var quizOptions: [QuizOption] = []
    var quizPick: String?
    var language = AppLanguage.fallback

    func t(_ key: String, _ args: [String: String] = [:]) -> String {
        I18n.t(key, language: language, args)
    }

    private var hideTask: Task<Void, Never>?
    private var appearTask: Task<Void, Never>?
    private var pebbleTask: Task<Void, Never>?
    private var hideDeadline: Date?
    private var hideRemaining: TimeInterval = Theme.hideDuration
    private var pointerInside = false
    private var settingsBackup: SettingsBackup?

    private struct SettingsBackup {
        var sel: [String: TypeSelection]
        var learnQuiz: Bool
        var learnInfo: Bool
        var language: AppLanguage
    }

    enum SetupPage: Equatable {
        case types
        case topics
        case learn
        case settings
    }

    func start() {
        language = AppLanguage(stored: UserConfig.load()?.language)
        I18n.load()
        do {
            catalog = try CatalogLoader.load(language: language)
            Self.log.notice("catálogo lang=\(self.language.rawValue, privacy: .public) cards=\(self.catalog.cards.count, privacy: .public)")
        } catch {
            loadError = error.localizedDescription
            catalog = Catalog(types: [], cards: [])
            Self.log.error("falha no YAML: \(error.localizedDescription, privacy: .public)")
        }
        apply(UserConfig.load() ?? .empty(types: catalog.types))
        if bootstrapped, canFinish {
            setupVisible = false
            let debugCard = ProcessInfo.processInfo.environment["PETZINHO_CARD"] != nil
            pickAndShow(open: debugCard)
            if !debugCard {
                scheduleAppear()
            }
        } else {
            bootstrapped = false
            openSetup(firstLaunch: true)
        }
    }

    var availableTypes: [StudyType] {
        catalog.types.filter(\.available)
    }

    func availableTopics(of type: StudyType) -> [Topic] {
        type.topics.filter(\.available)
    }

    var selectedTypeIds: [String] {
        catalog.types.compactMap { type in
            (sel[type.id]?.on == true && type.available) ? type.id : nil
        }
    }

    var canContinueTypes: Bool { !selectedTypeIds.isEmpty }
    var topicCount: Int {
        selectedTypeIds.reduce(0) { $0 + (sel[$1]?.topics.count ?? 0) }
    }
    var canFinish: Bool { topicCount > 0 }
    var canFinishLearn: Bool { learnQuiz || learnInfo }
    var canComplete: Bool { canFinish && canFinishLearn }

    func allTypesOn() -> Bool {
        let types = availableTypes
        return !types.isEmpty && types.allSatisfy { sel[$0.id]?.on == true }
    }

    func allTopicsOn(of type: StudyType) -> Bool {
        let topics = availableTopics(of: type)
        return !topics.isEmpty && topics.allSatisfy { sel[type.id]?.topics.contains($0.id) == true }
    }

    func topicOn(typeId: String, topicId: String) -> Bool {
        sel[typeId]?.topics.contains(topicId) == true
    }

    func toggleType(_ id: String) {
        guard let type = catalog.type(id: id), type.available else { return }
        var slot = sel[id] ?? TypeSelection(on: false, topics: [])
        if slot.on {
            slot.on = false
            slot.topics = []
        } else {
            slot.on = true
            slot.topics = Set(availableTopics(of: type).map(\.id))
        }
        sel[id] = slot
    }

    func toggleAllTypes() {
        if allTypesOn() {
            resetSel()
        } else {
            for type in availableTypes {
                sel[type.id] = TypeSelection(on: true, topics: Set(availableTopics(of: type).map(\.id)))
            }
        }
    }

    func toggleTopic(typeId: String, topicId: String) {
        guard let type = catalog.type(id: typeId), type.available,
              let topic = catalog.topic(typeId: typeId, topicId: topicId), topic.available
        else { return }
        var slot = sel[typeId] ?? TypeSelection(on: false, topics: [])
        if slot.topics.contains(topicId) {
            slot.topics.remove(topicId)
        } else {
            slot.topics.insert(topicId)
        }
        slot.on = true
        sel[typeId] = slot
    }

    func toggleAllTopics(typeId: String) {
        guard let type = catalog.type(id: typeId), type.available else { return }
        var slot = sel[typeId] ?? TypeSelection(on: false, topics: [])
        if allTopicsOn(of: type) {
            slot.topics = []
            slot.on = true
        } else {
            slot.topics = Set(availableTopics(of: type).map(\.id))
            slot.on = true
        }
        sel[typeId] = slot
    }

    func goTopics() {
        guard canContinueTypes else { return }
        setupPage = .topics
    }

    func goTypes() {
        setupPage = .types
    }

    func goLearn() {
        setupPage = .learn
    }

    func toggleLearnQuiz() {
        if learnQuiz, !learnInfo { return }
        learnQuiz.toggle()
    }

    func toggleLearnInfo() {
        if learnInfo, !learnQuiz { return }
        learnInfo.toggle()
    }

    func finishBootstrap() {
        guard commitSetup() else { return }
        closeSetup()
        forceTip()
    }

    @discardableResult
    func commitSetup() -> Bool {
        guard canComplete, loadError == nil else { return false }
        bootstrapped = true
        settingsBackup = nil
        persist()
        return true
    }

    func openSetup(firstLaunch: Bool = false) {
        guard !setupVisible else {
            SetupWindowController.shared.show()
            NSApp.activate()
            return
        }
        if bootstrapped {
            setupPage = .settings
            settingsBackup = SettingsBackup(sel: sel, learnQuiz: learnQuiz, learnInfo: learnInfo, language: language)
        } else {
            setupPage = .learn
            if !firstLaunch, sel.isEmpty { resetSel() }
        }
        setupVisible = true
        SetupWindowController.shared.show()
        NSApp.activate()
    }

    func closeSetup() {
        setupVisible = false
        SetupWindowController.shared.hide()
    }

    func saveSettings() {
        guard commitSetup() else { return }
        closeSetup()
    }

    func cancelSettings() {
        restoreSettingsBackup()
        closeSetup()
    }

    func handleSetupClosed() {
        setupVisible = false
        if setupPage == .settings {
            restoreSettingsBackup()
        }
        if bootstrapped, !widgetVisible {
            forceTip()
        }
    }

    private func restoreSettingsBackup() {
        guard let backup = settingsBackup else { return }
        sel = backup.sel
        learnQuiz = backup.learnQuiz
        learnInfo = backup.learnInfo
        settingsBackup = nil
        setLanguage(backup.language)
    }

    func setLanguage(_ next: AppLanguage) {
        guard next != language else { return }
        language = next
        let keepId = currentCard?.id
        let keepKind = tipKind
        reloadCatalog()
        pruneSelToCatalog()
        persist()
        if let keepId, let card = catalog.cards.first(where: { $0.id == keepId }) {
            currentCard = card
            configureDelivery()
            if keepKind == .quiz, !quizOptions.isEmpty {
                tipKind = .quiz
            } else if keepKind == .info {
                tipKind = .info
                quizOptions = []
            }
        } else if bootstrapped {
            currentCard = nil
            forceTip()
        }
        WidgetPanelController.shared.refresh()
        if setupVisible {
            SetupWindowController.shared.show()
        }
    }

    private func reloadCatalog() {
        do {
            catalog = try CatalogLoader.load(language: language)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            Self.log.error("falha no YAML: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func pruneSelToCatalog() {
        var next: [String: TypeSelection] = [:]
        for type in catalog.types {
            let slot = sel[type.id] ?? TypeSelection(on: false, topics: [])
            let valid = Set(type.topics.map(\.id))
            let topics = slot.topics.intersection(valid)
            next[type.id] = TypeSelection(on: slot.on && type.available, topics: topics)
        }
        sel = next
    }

    func forceTip() {
        guard bootstrapped else { return }
        cancelAppear()
        pickAndShow(open: true)
    }

    func toggleBubble() {
        guard bootstrapped, widgetVisible else { return }
        if bubbleOpen {
            closeBubble()
        } else {
            openBubble()
        }
    }

    func openBubble() {
        guard bootstrapped, widgetVisible, !bubbleOpen else { return }
        pebbleTask?.cancel()
        pebbleTask = nil
        if currentCard == nil {
            forceTip()
            return
        }
        setBubbleOpen(true, restartClock: true)
    }

    func setDock(_ next: DockAnchor) {
        dock = next
        persist()
        WidgetPanelController.shared.refresh()
    }

    func setDeep(_ deep: Bool) {
        guard bubbleOpen else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            bubbleDeep = deep
        }
        Self.log.notice("deep=\(deep, privacy: .public) kind=\(self.tipKind.rawValue, privacy: .public) card=\(self.currentCard?.id ?? "-", privacy: .public)")
        if deep, let card = currentCard {
            WidgetPanelController.shared.prepareExpansion(card: card)
        }
        WidgetPanelController.shared.refresh()
        WidgetPanelController.shared.bringForward()
    }

    func answerQuiz(_ id: String) {
        guard tipKind == .quiz, quizPick == nil, quizOptions.contains(where: { $0.id == id }) else { return }
        quizPick = id
        setDeep(true)
    }

    func toggleDeep() {
        setDeep(!bubbleDeep)
    }

    func setPointerInside(_ inside: Bool) {
        guard pointerInside != inside else { return }
        pointerInside = inside
        if inside {
            pauseHide()
        } else {
            armHide()
        }
    }

    func closeBubble() {
        setBubbleOpen(false, restartClock: false)
        pebbleTask?.cancel()
        pebbleTask = nil
        scheduleAppear()
    }

    func dismissWidget() {
        closeBubble()
    }

    func quit() {
        cancelAppear()
        hideTask?.cancel()
        hideTask = nil
        pebbleTask?.cancel()
        pebbleTask = nil
        widgetVisible = false
        bubbleOpen = false
        NSApp.terminate(nil)
    }

    private func pickAndShow(open: Bool) {
        let forcedId = ProcessInfo.processInfo.environment["PETZINHO_CARD"]
        if let forcedId, let card = catalog.cards.first(where: { $0.id == forcedId }) {
            currentCard = card
            lastShownId = card.id
        } else if let card = pickNext() {
            currentCard = card
            lastShownId = card.id
            persist()
        } else {
            currentCard = emptyCard()
        }
        widgetVisible = true
        configureDelivery()
        if open {
            setBubbleOpen(true, restartClock: true)
            if ProcessInfo.processInfo.environment["PETZINHO_DEEP"] == "1", tipKind != .quiz {
                setDeep(true)
            }
        } else {
            bubbleOpen = false
            bubbleDeep = false
        }
        WidgetPanelController.shared.refresh()
    }

    private func configureDelivery() {
        quizPick = nil
        bubbleDeep = false
        let bag = pool()
        guard let card = currentCard else {
            tipKind = .info
            quizOptions = []
            return
        }
        let options = QuizFactory.options(for: card, pool: bag)
        let forced = ProcessInfo.processInfo.environment["PETZINHO_KIND"]
        if forced == "info" {
            tipKind = .info
            quizOptions = []
            return
        }
        if forced == "quiz", !options.isEmpty {
            tipKind = .quiz
            quizOptions = options
            return
        }
        let wantQuiz = learnQuiz && !options.isEmpty
        let wantInfo = learnInfo
        switch (wantQuiz, wantInfo) {
        case (true, true):
            tipKind = Bool.random() ? .quiz : .info
        case (true, false):
            tipKind = .quiz
        default:
            tipKind = .info
        }
        quizOptions = tipKind == .quiz ? options : []
    }

    private func setBubbleOpen(_ next: Bool, restartClock: Bool) {
        let was = bubbleOpen
        if next {
            WidgetPanelController.shared.cancelCloseHold()
        } else {
            WidgetPanelController.shared.holdSizeForClose()
        }
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) {
            bubbleOpen = next
            if !next {
                bubbleDeep = false
            }
        }
        if !next {
            hideRemaining = Theme.hideDuration
            hideTask?.cancel()
            hideDeadline = nil
            return
        }
        if !was || restartClock {
            hideRemaining = Theme.hideDuration
            armHide()
        }
        WidgetPanelController.shared.refresh()
    }

    private func pool() -> [Card] {
        catalog.cards.filter { card in
            guard let slot = sel[card.objectId], slot.on else { return false }
            guard let type = catalog.type(id: card.objectId), type.available else { return false }
            return slot.topics.contains(card.topicId)
        }
    }

    private func pickNext() -> Card? {
        let bag0 = pool()
        guard !bag0.isEmpty else { return nil }
        let bag = bag0.filter { $0.id != lastShownId }
        let use = bag.isEmpty ? bag0 : bag
        return use.randomElement()
    }

    private func emptyCard() -> Card {
        let type = catalog.type(id: selectedTypeIds.first ?? "development")
        return Card(
            id: "empty",
            objectId: type?.id ?? "development",
            topicId: type?.topics.first?.id ?? "solid",
            topic: type?.label ?? "Programação",
            mark: "·",
            frente: "Nada neste recorte",
            verso: "Não há dica para os tópicos marcados. Abre a configuração e inclui um tópico com notas.",
            nota: "",
            codigo: "",
            depois: "",
            mapa: nil,
            quiz: nil
        )
    }

    private func armHide() {
        hideTask?.cancel()
        hideDeadline = nil
        guard bubbleOpen, !pointerInside else { return }
        if hideRemaining <= 0 {
            closeBubble()
            return
        }
        let remaining = hideRemaining
        hideDeadline = Date().addingTimeInterval(remaining)
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            closeBubble()
        }
    }

    private func pauseHide() {
        guard bubbleOpen, hideTask != nil, let deadline = hideDeadline else { return }
        hideRemaining = max(0, deadline.timeIntervalSinceNow)
        hideDeadline = nil
        hideTask?.cancel()
        hideTask = nil
    }

    private func scheduleAppear() {
        cancelAppear()
        guard bootstrapped else { return }
        let jitter = 1 + Double.random(in: -Theme.appearJitter...Theme.appearJitter)
        let delay = Theme.appearCenter * jitter
        appearTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            pickAndShow(open: true)
        }
    }

    private func cancelAppear() {
        appearTask?.cancel()
        appearTask = nil
        pebbleTask?.cancel()
        pebbleTask = nil
    }

    private func resetSel() {
        sel = Dictionary(
            uniqueKeysWithValues: catalog.types.map { ($0.id, TypeSelection(on: false, topics: [])) }
        )
    }

    private func apply(_ config: UserConfig) {
        bootstrapped = config.bootstrapped
        lastShownId = config.lastShownId
        language = AppLanguage(stored: config.language)
        learnQuiz = config.learnQuiz ?? true
        learnInfo = config.learnInfo ?? true
        if !learnQuiz, !learnInfo {
            learnQuiz = true
            learnInfo = true
        }
        if let raw = config.dockEdge, let edge = DockEdge(rawValue: raw) {
            dock = DockAnchor(edge: edge, along: CGFloat(config.dockAlong ?? Double(DockAnchor.fallback.along)))
        } else {
            dock = .fallback
        }
        var next: [String: TypeSelection] = [:]
        for type in catalog.types {
            let slot = config.sel[type.id]
            next[type.id] = TypeSelection(on: slot?.on ?? false, topics: Set(slot?.topics ?? []))
        }
        sel = next
        if bootstrapped, !canFinish {
            bootstrapped = false
        }
    }

    private func persist() {
        UserConfig(
            bootstrapped: bootstrapped,
            sel: (settingsBackup?.sel ?? sel).mapValues { UserConfig.Slot(on: $0.on, topics: Array($0.topics).sorted()) },
            lastShownId: lastShownId,
            dockEdge: dock.edge.rawValue,
            dockAlong: Double(dock.along),
            learnQuiz: settingsBackup?.learnQuiz ?? learnQuiz,
            learnInfo: settingsBackup?.learnInfo ?? learnInfo,
            language: (settingsBackup?.language ?? language).rawValue
        ).save()
    }
}
