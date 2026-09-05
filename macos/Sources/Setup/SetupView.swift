import AppKit
import SwiftUI

private struct SetupContentHeight: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct SetupWindowHeight: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct SetupCelebration: View {
    let title: String
    let subtitle: String
    let button: String
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(setupAccent.opacity(0.09))
                    .frame(width: 124, height: 124)
                    .scaleEffect(appeared ? 1 : 0.7)
                ForEach(0..<10) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "circle.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 13 : 5))
                        .foregroundStyle(setupAccent.opacity(0.8))
                        .offset(y: appeared ? -86 : -40)
                        .rotationEffect(.degrees(Double(index) * 36))
                        .opacity(appeared ? 1 : 0)
                }
                Image("Bonequinho")
                    .resizable().interpolation(.none)
                    .frame(width: 64, height: 64)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .rotationEffect(.degrees(appeared ? 0 : -12))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(setupAccent, Theme.sheet)
                    .offset(x: 42, y: 42)
                    .scaleEffect(appeared ? 1 : 0)
            }
            .frame(height: 190)
            .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 27, weight: .semibold))
                .tracking(-0.5)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button(button, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 10)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.sheet)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.65)) {
                appeared = true
            }
        }
    }
}


private let setupAccent = Color(red: 0.94, green: 0.65, blue: 0.39)

struct SetupRoot: View {
    @Bindable var session: Session
    var body: some View {
        SetupView(session: session)
            .frame(width: 560)
            .preferredColorScheme(.dark)
            .tint(setupAccent)
            .background(Theme.sheet)
    }
}

struct SetupView: View {
    @Bindable var session: Session
    @Bindable private var updater = AppUpdater.shared
    @State private var settingsStep = 0
    @State private var query = ""
    @State private var completed = false
    @State private var contentHeight: CGFloat = 420
    private var sections: [String] { ["learn", "types", "topics"] }
    private var isSettings: Bool { session.setupPage == .settings }
    private var step: Int {
        if isSettings { return settingsStep }
        switch session.setupPage {
        case .learn: return 0
        case .types: return 1
        case .topics: return 2
        case .settings: return settingsStep
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            navigation
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(session.t("setup.\(sections[step]).title"))
                            .font(.system(size: 24, weight: .semibold)).tracking(-0.5)
                        Text(session.t("setup.\(sections[step]).hint"))
                            .font(.system(size: 13)).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let error = session.loadError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.system(size: 12)).foregroundStyle(.orange)
                    }
                    switch step {
                    case 0: learning
                    case 1: themes
                    default: categories
                    }
                    footer
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: SetupContentHeight.self, value: geometry.size.height)
                    }
                }
            }
            .frame(height: min(contentHeight, max(180, (NSScreen.main?.visibleFrame.height ?? 800) - 200)))
            .onPreferenceChange(SetupContentHeight.self) { height in
                if height > 0 { contentHeight = ceil(height) }
            }
        }
        .frame(minHeight: completed ? 460 : nil)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: SetupWindowHeight.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(SetupWindowHeight.self) { height in
            SetupWindowController.shared.fitContent(height: height)
        }
        .foregroundStyle(Theme.text)
        .disabled(completed)
        .accessibilityHidden(completed)
        .overlay {
            if completed {
                SetupCelebration(
                    title: session.t("setup.done.title"),
                    subtitle: session.t("setup.done.hint"),
                    button: session.t("setup.done.action")
                ) {
                    session.closeSetup()
                    session.forceTip()
                }
            }
        }
        .onChange(of: step) { _, _ in query = "" }
        .onChange(of: session.setupVisible) { _, visible in
            if visible { settingsStep = 0; query = ""; completed = false }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image("Bonequinho")
                .resizable().interpolation(.none)
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
            Text("Breve")
                .font(.system(size: 17, weight: .semibold))
            Text(session.t("setup.header.version", ["version": updater.currentVersion]))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.muted)
                .accessibilityLabel(session.t("setup.update.current", [
                    "version": updater.currentVersion,
                    "build": updater.currentBuild
                ]))
            Spacer()
            updateButton
            languageFlag("🇧🇷", language: .pt, label: "lang.pt")
            languageFlag("🇺🇸", language: .en, label: "lang.en")
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var updateButton: some View {
        let checking = updater.status == .checking
        return Button {
            updater.present()
        } label: {
            ZStack {
                if checking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: updateSymbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(updateTint)
                }
            }
            .frame(width: 42, height: 34)
            .background(updateBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(updateBorder))
        }
        .buttonStyle(.plain)
        .disabled(!updater.canCheck)
        .help(updateHelp)
        .accessibilityLabel(updateHelp)
        .accessibilityValue(updateStatusText)
        .accessibilityHint(session.t("setup.update.confirm"))
    }

    private var updateSymbol: String {
        switch updater.status {
        case .available: "arrow.down.circle.fill"
        case .error: "exclamationmark.circle"
        case .upToDate: "checkmark.circle"
        case .idle, .checking: "arrow.clockwise"
        }
    }

    private var updateTint: Color {
        switch updater.status {
        case .available: setupAccent
        case .error: .orange
        case .upToDate: Theme.muted
        case .idle, .checking: Theme.text
        }
    }

    private var updateBackground: Color {
        switch updater.status {
        case .available: setupAccent.opacity(0.12)
        case .error: Color.orange.opacity(0.12)
        default: Color.white.opacity(0.035)
        }
    }

    private var updateBorder: Color {
        switch updater.status {
        case .available: setupAccent.opacity(0.8)
        case .error: Color.orange.opacity(0.7)
        default: .clear
        }
    }

    private var updateHelp: String {
        switch updater.status {
        case .available: session.t("setup.update.icon.available")
        case .checking: session.t("setup.update.icon.checking")
        default: session.t("setup.update.icon")
        }
    }

    private var navigation: some View {
        HStack(spacing: 8) {
            ForEach(0..<sections.count, id: \.self) { index in
                Button { navigate(to: index) } label: {
                    HStack(spacing: 8) {
                        if !isSettings {
                            Text("\(index + 1)")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 22, height: 22)
                            .background(step == index ? setupAccent : Color.white.opacity(0.08), in: Circle())
                            .foregroundStyle(step == index ? Theme.sheet : Theme.muted)
                        }
                        Text(session.t("setup.nav.\(sections[index])"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer(minLength: 0)
                    }
                    .frame(height: 22)
                    .padding(10)
                    .background(step == index ? setupAccent.opacity(0.12) : Color.white.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(step == index ? setupAccent.opacity(0.65) : Color.white.opacity(0.16))
                    }
                    .foregroundStyle(step == index ? setupAccent : Theme.text)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isSettings && index > step)
                .accessibilityAddTraits(step == index ? .isSelected : [])
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private func languageFlag(_ flag: String, language: AppLanguage, label: String) -> some View {
        let selected = session.language == language
        return Button { session.setLanguage(language) } label: {
            Text(flag)
                .font(.system(size: 22))
                .frame(width: 42, height: 34)
                .background(selected ? setupAccent.opacity(0.12) : Color.white.opacity(0.035),
                            in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(selected ? setupAccent.opacity(0.8) : .clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(session.t(label))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help(session.t(label))
    }

    private var learning: some View {
        VStack(spacing: 10) {
            mode("quiz", icon: "questionmark.bubble", quiz: true, info: false)
            mode("info", icon: "text.book.closed", quiz: false, info: true)
            mode("both", icon: "square.stack", quiz: true, info: true)
            Label(session.t("setup.change_later"), systemImage: "slider.horizontal.3")
                .font(.system(size: 12)).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
        }
    }

    private func mode(_ key: String, icon: String, quiz: Bool, info: Bool) -> some View {
        let selected = session.learnQuiz == quiz && session.learnInfo == info
        return Button {
            session.learnQuiz = quiz
            session.learnInfo = info
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 21))
                    .foregroundStyle(selected ? setupAccent : Theme.muted).frame(width: 30)
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.t("setup.mode.\(key)")).font(.system(size: 14, weight: .semibold))
                    Text(session.t("setup.mode.\(key)_hint"))
                        .font(.system(size: 12)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? setupAccent : Theme.muted)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? setupAccent.opacity(0.08) : Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? setupAccent.opacity(0.7) : Color.white.opacity(0.09)))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var themes: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(session.catalog.types) { type in
                let selected = session.sel[type.id]?.on == true
                Button { session.toggleType(type.id) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: themeIcon(type.id))
                            .font(.system(size: 21))
                            .foregroundStyle(selected ? setupAccent : Theme.muted)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(type.label).font(.system(size: 14, weight: .semibold))
                            Text(type.available
                                 ? session.t("setup.theme." + type.id)
                                 : session.t("setup.coming_soon"))
                                .font(.system(size: 12)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: selected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(selected ? setupAccent : Theme.muted)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(selected ? setupAccent.opacity(0.08) : Color.white.opacity(0.035),
                                in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(selected ? setupAccent.opacity(0.7) : Color.white.opacity(0.09)))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!type.available)
                .opacity(type.available ? 1 : 0.55)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func themeIcon(_ id: String) -> String {
        switch id {
        case "development": return "chevron.left.forwardslash.chevron.right"
        case "marketing": return "megaphone"
        case "mathematics": return "function"
        default: return "book.closed"
        }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 16) {
            if session.selectedTypeIds.isEmpty {
                Label(session.t("setup.select_theme"), systemImage: "folder").foregroundStyle(Theme.muted)
                Button(session.t("setup.choose_themes")) { navigate(to: 1) }
            } else {
                TextField(session.t("setup.search"), text: $query).textFieldStyle(.roundedBorder)
                    .accessibilityLabel(session.t("setup.search"))
                ForEach(session.catalog.types.filter { session.selectedTypeIds.contains($0.id) }) { type in
                    let topics = type.topics.filter { matches($0, type: type) }
                    if !topics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(type.label).font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Button(session.t(session.allTopicsOn(of: type) ? "setup.clear_all" : "setup.select_all")) {
                                    session.toggleAllTopics(typeId: type.id)
                                }
                                .font(.system(size: 11)).buttonStyle(.link)
                            }
                            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 14) {
                                ForEach(topics) { topic in
                                    Toggle(topic.label, isOn: Binding(
                                        get: { session.topicOn(typeId: type.id, topicId: topic.id) },
                                        set: { _ in session.toggleTopic(typeId: type.id, topicId: topic.id) }
                                    ))
                                    .toggleStyle(.checkbox).font(.system(size: 12))
                                    .disabled(!topic.available)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                if !query.isEmpty && !session.catalog.types.contains(where: { type in
                    session.selectedTypeIds.contains(type.id) && type.topics.contains { matches($0, type: type) }
                }) {
                    Text(session.t("setup.empty_search", ["query": query])).font(.system(size: 13)).foregroundStyle(Theme.muted)
                }
            }
        }
    }

    private func matches(_ topic: Topic, type: StudyType) -> Bool {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty || topic.label.localizedStandardContains(text) || type.label.localizedStandardContains(text)
    }

    private var updateStatusText: String {
        switch updater.status {
        case .idle:
            session.t("setup.update.idle")
        case .checking:
            session.t("setup.update.checking")
        case .upToDate:
            session.t("setup.update.none", ["version": updater.currentVersion])
        case .available(let version, let build):
            session.t("setup.update.available", ["version": version, "build": build])
        case .error(let message):
            session.t("setup.update.error", ["message": message])
        }
    }

    private var footer: some View {
        HStack {
            if step > 0 {
                Button(session.t("setup.back")) { navigate(to: step - 1) }
            }
            if isSettings && step == 0 {
                Button(session.t("setup.cancel"), action: session.cancelSettings)
                    .keyboardShortcut(.cancelAction)
            }
            Spacer()
            Button(session.t(isSettings ? "setup.save" : step < 2 ? "setup.continue" : "setup.start")) {
                if !isSettings && step < 2 { navigate(to: step + 1) }
                else if session.commitSetup() { completed = true }
            }
            .buttonStyle(.borderedProminent)
            .disabled(session.loadError != nil || (isSettings ? !session.canComplete : step == 0 ? !session.canFinishLearn : step == 1 ? !session.canContinueTypes : !session.canComplete))
            .keyboardShortcut(.defaultAction)
        }
        .controlSize(.large)
        .padding(.top, 4)
    }

    private func navigate(to index: Int) {
        query = ""
        if isSettings { settingsStep = index }
        else {
            switch index {
            case 0: session.goLearn()
            case 1: session.goTypes()
            default: session.goTopics()
            }
        }
    }
}
