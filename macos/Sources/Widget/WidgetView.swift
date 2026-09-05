import AppKit
import SwiftUI

struct WidgetRoot: View {
    @Bindable var session: Session

    var body: some View {
        WidgetView(session: session)
            .environment(\.colorScheme, .dark)
    }
}

struct WidgetView: View {
    @Bindable var session: Session

    private var edge: DockEdge { session.dock.edge }

    private var clusterAlignment: Alignment {
        switch edge {
        case .right: .topTrailing
        case .left: .topLeading
        case .top: .top
        case .bottom: .bottom
        }
    }

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .overlay(alignment: clusterAlignment) {
                cluster
                    .padding(Theme.clusterInsets(for: edge))
                    .fixedSize()
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: WidgetContentSizeKey.self, value: geo.size)
                        }
                    }
            }
            .onPreferenceChange(WidgetContentSizeKey.self) { size in
                WidgetPanelController.shared.adoptContentSize(size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: clusterAlignment)
    }

    @ViewBuilder
    private var cluster: some View {
        let pet = face.transaction { $0.animation = nil }
        switch edge {
        case .right:
            HStack(alignment: .top, spacing: Theme.gap) {
                speech
                pet
            }
        case .left:
            HStack(alignment: .top, spacing: Theme.gap) {
                pet
                speech
            }
        case .top:
            VStack(spacing: Theme.gap) {
                pet
                speech
            }
        case .bottom:
            VStack(spacing: Theme.gap) {
                speech
                pet
            }
        }
    }

    @ViewBuilder
    private var speech: some View {
        if session.bubbleOpen, let card = session.currentCard {
            SpeechBubble(
                card: card,
                type: session.catalog.type(id: card.objectId),
                deep: session.bubbleDeep,
                edge: edge,
                kind: session.tipKind,
                quizOptions: session.quizOptions,
                quizPick: session.quizPick
            )
            .id("\(card.id)-\(session.language.rawValue)-\(session.tipKind.rawValue)")
            .transition(
                .scale(scale: 0.96, anchor: bubbleAnchor)
                    .combined(with: .opacity)
            )
        }
    }

    private var face: some View {
        Image("Bonequinho")
            .resizable()
            .interpolation(.high)
            .frame(width: Theme.face, height: Theme.face)
            .contentShape(Circle())
            .layoutPriority(1)
            .accessibilityLabel(session.bubbleOpen ? session.t("widget.close") : session.t("widget.open"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                session.toggleBubble()
            }
            .hitRegion("pet", [.click, .solid])
    }

    private var bubbleAnchor: UnitPoint {
        switch edge {
        case .right: .trailing
        case .left: .leading
        case .top: .top
        case .bottom: .bottom
        }
    }
}

private struct WidgetContentSizeKey: PreferenceKey {
    static let defaultValue = CGSize.zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next.width > 0 { value = next }
    }
}

private struct SpeechBubble: View {
    let card: Card
    let type: StudyType?
    let deep: Bool
    let edge: DockEdge
    let kind: TipKind
    let quizOptions: [QuizOption]
    let quizPick: String?

    private let padX: CGFloat = 16
    private let padTop: CGFloat = 14

    private var headline: String {
        kind == .info ? card.verso : card.frente
    }

    private var questionInnerWidth: CGFloat {
        Theme.questionWidth(headline)
    }

    private var expandedInnerWidth: CGFloat {
        max(Theme.expandedBubbleInnerWidth(question: headline, card: card), kind == .quiz ? 360 : 0)
    }

    private var innerWidth: CGFloat {
        deep || kind == .quiz ? expandedInnerWidth : questionInnerWidth
    }

    private var bubbleOuterWidth: CGFloat {
        innerWidth + padX * 2
    }

    private var canToggleDeep: Bool {
        kind != .quiz && card.hasExtra
    }

    private var showsChevron: Bool { canToggleDeep }

    private var tailAlignment: Alignment {
        switch edge {
        case .right: .topTrailing
        case .left: .topLeading
        case .top: .top
        case .bottom: .bottom
        }
    }

    private var tailOffset: CGSize {
        switch edge {
        case .right: CGSize(width: 6, height: 22)
        case .left: CGSize(width: -6, height: 22)
        case .top: CGSize(width: 0, height: -6)
        case .bottom: CGSize(width: 0, height: 6)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            headlineRow
            if kind == .quiz {
                quizBlock
            }
            if showsExplanation {
                explanation(includeVerso: kind == .quiz)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if showsChevron {
                moreButton
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
        .padding(.top, padTop)
        .padding(.horizontal, padX)
        .padding(.bottom, showsChevron ? 14 : 16)
        .frame(width: bubbleOuterWidth, alignment: .leading)
        .background(Theme.bubble, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .hitRegion("bubble-\(card.id)", .solid)
        .overlay(alignment: tailAlignment) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Theme.bubble)
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(45))
                .offset(tailOffset)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(compactLabel)
    }

    private var showsExplanation: Bool {
        if kind == .quiz { return quizPick != nil }
        return deep && card.hasExtra
    }

    private var compactLabel: String {
        kind == .quiz ? Session.shared.t("widget.quiz") : Session.shared.t("widget.info")
    }

    private var moreButton: some View {
        Button(action: toggle) {
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 17 / 255, green: 17 / 255, blue: 19 / 255))
                .rotationEffect(.degrees(deep ? 180 : 0))
                .animation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2), value: deep)
                .frame(width: Theme.chevron, height: Theme.chevron)
                .background(Circle().fill(.white))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .pointerHand()
        .hitRegion("chevron-\(card.id)", [.click, .solid])
        .accessibilityLabel(deep ? Session.shared.t("widget.collapse") : Session.shared.t("widget.more"))
    }

    @ViewBuilder
    private var header: some View {
        if canToggleDeep {
            Button(action: toggle) {
                badges
            }
            .buttonStyle(PressableStyle())
            .pointerHand()
            .hitRegion("badges-\(card.id)")
        } else {
            badges
        }
    }

    @ViewBuilder
    private var headlineRow: some View {
        let body = MarkdownBody(
            source: headline,
            size: 14,
            weight: .semibold,
            color: Theme.text,
            fillWidth: false
        )
        if canToggleDeep {
            Button(action: toggle) {
                body
            }
            .buttonStyle(PressableStyle())
            .pointerHand()
            .hitRegion("headline-\(card.id)")
        } else {
            body
        }
    }

    @ViewBuilder
    private var quizBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(quizOptions) { option in
                QuizOptionRow(option: option, pick: quizPick) {
                    Session.shared.answerQuiz(option.id)
                }
            }
        }
    }

    @ViewBuilder
    private func explanation(includeVerso: Bool) -> some View {
        let hasExplain = includeVerso || !card.nota.isEmpty
        VStack(alignment: .leading, spacing: 12) {
            if hasExplain {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Session.shared.t("widget.explain"))
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.label)
                    if includeVerso {
                        MarkdownBody(source: card.verso, size: 13, weight: .semibold, color: Theme.text, selectable: true)
                    }
                    if !card.nota.isEmpty {
                        MarkdownBody(source: card.nota, size: 13, color: Theme.text.opacity(0.82), selectable: true)
                    }
                }
            }

            if card.hasMap, let mapa = card.mapa {
                ConceptMapView(map: mapa)
            }

            if card.hasCode {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Session.shared.t("widget.example"))
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.label)
                    CodeBlock(code: card.codigo)
                }
            }

            if !card.depois.isEmpty {
                MarkdownBody(source: card.depois, size: 13, color: Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var badges: some View {
        HStack(spacing: 6) {
            if let type {
                Text(type.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.toneForeground(type.tone))
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Theme.toneBackground(type.tone), in: Capsule())
            }
            HStack(spacing: 5) {
                Text(card.mark)
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 14, height: 14)
                    .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text(card.topic)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.white.opacity(0.82))
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .frame(height: 20)
            .background(Color.white.opacity(0.08), in: Capsule())
            Text(kind == .quiz ? Session.shared.t("widget.quiz") : Session.shared.t("widget.info"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.62))
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
    }

    private func toggle() {
        Session.shared.setDeep(!deep)
    }
}

private struct QuizOptionRow: View {
    let option: QuizOption
    let pick: String?
    let action: () -> Void
    @State private var hovering = false

    private var revealed: Bool { pick != nil }
    private var chosen: Bool { pick == option.id }

    private let green = Color(red: 0.36, green: 0.92, blue: 0.52)
    private let red = Color(red: 1.0, green: 0.42, blue: 0.38)

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(dotFill)
                    .overlay(Circle().strokeBorder(dotStroke, lineWidth: 1.5))
                    .frame(width: 16, height: 16)
                    .padding(.top, 2)
                Text(option.text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(labelColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(stroke, lineWidth: mark == .idle || mark == .dim ? 1 : 1.5)
            )
        }
        .buttonStyle(PressableStyle())
        .contentShape(Rectangle())
        .pointerHand(enabled: !revealed)
        .hitRegion("opt-\(option.id)", revealed ? [] : [.click, .solid])
        .onHover { hovering = $0 }
        .disabled(revealed)
        .accessibilityLabel(option.text)
        .accessibilityAddTraits(option.correct && revealed ? .isSelected : [])
    }

    private enum Mark { case idle, correct, wrong, dim }

    private var mark: Mark {
        guard revealed else { return .idle }
        if option.correct { return .correct }
        if chosen { return .wrong }
        return .dim
    }

    private var fill: Color {
        switch mark {
        case .correct: green.opacity(0.28)
        case .wrong: red.opacity(0.32)
        case .dim: Color.white.opacity(0.03)
        case .idle: Color.white.opacity(hovering ? 0.14 : 0.07)
        }
    }

    private var stroke: Color {
        switch mark {
        case .correct: green
        case .wrong: red
        case .dim: Color.white.opacity(0.06)
        case .idle: Color.white.opacity(hovering ? 0.32 : 0.14)
        }
    }

    private var labelColor: Color {
        switch mark {
        case .correct: Color(red: 0.78, green: 1.0, blue: 0.84)
        case .wrong: Color(red: 1.0, green: 0.82, blue: 0.80)
        case .dim: Color.white.opacity(0.38)
        case .idle: Theme.text
        }
    }

    private var dotFill: Color {
        switch mark {
        case .correct: green
        case .wrong: red
        case .dim, .idle: Color.clear
        }
    }

    private var dotStroke: Color {
        switch mark {
        case .correct: green
        case .wrong: red
        case .dim: Color.white.opacity(0.16)
        case .idle: Color.white.opacity(hovering ? 0.55 : 0.32)
        }
    }
}

private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
