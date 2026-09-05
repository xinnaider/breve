import SwiftUI

struct PickBadge: View {
    enum Kind {
        case all
        case toned(Tone)
    }

    let label: String
    let pressed: Bool
    var kind: Kind = .all
    var mark: String?
    var disabled = false
    var help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let mark, !mark.isEmpty {
                    Text(mark)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.leading, mark == nil ? 10 : 8)
            .padding(.trailing, 10)
            .frame(height: 28)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
        .pointerHand(enabled: !disabled)
        .disabled(disabled)
        .opacity(disabled ? 0.38 : 1)
        .modifier(OptionalHelp(help))
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(pressed ? .isSelected : [])
    }

    private var background: Color {
        guard pressed else { return Color.white.opacity(0.07) }
        switch kind {
        case .all: return .white
        case .toned(let tone): return Theme.toneBackground(tone)
        }
    }

    private var foreground: Color {
        guard pressed else { return Color.white.opacity(0.78) }
        switch kind {
        case .all: return Color(red: 17 / 255, green: 17 / 255, blue: 19 / 255)
        case .toned(let tone): return Theme.toneForeground(tone)
        }
    }
}

private struct OptionalHelp: ViewModifier {
    var text: String?
    init(_ text: String?) { self.text = text }
    func body(content: Content) -> some View {
        if let text, !text.isEmpty {
            content.help(text)
        } else {
            content
        }
    }
}
