import SwiftUI

struct MarkdownBody: View {
    let source: String
    var size: CGFloat = 13
    var weight: Font.Weight = .regular
    var color: Color = Theme.text.opacity(0.82)
    var selectable = false
    var fillWidth = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(Self.blocks(source).enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let text):
                    textView(Self.attributed(text, size: size, weight: weight, color: color))
                case .list(let items):
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.system(size: size, weight: .semibold))
                                    .foregroundStyle(color)
                                textView(Self.attributed(item, size: size, weight: weight, color: color))
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: fillWidth ? .infinity : nil, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private func textView(_ value: AttributedString) -> some View {
        let view = Text(value)
            .fixedSize(horizontal: false, vertical: true)
        if selectable {
            view.textSelection(.enabled)
        } else {
            view
        }
    }

    private enum Block {
        case paragraph(String)
        case list([String])
    }

    private static func blocks(_ source: String) -> [Block] {
        let lines = source
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", omittingEmptySubsequences: false)
        var result: [Block] = []
        var list: [String] = []

        func flushList() {
            guard !list.isEmpty else { return }
            result.append(.list(list))
            list = []
        }

        for line in lines {
            let raw = String(line).trimmingCharacters(in: .whitespaces)
            if raw.isEmpty {
                flushList()
                continue
            }
            if raw.hasPrefix("- ") {
                list.append(String(raw.dropFirst(2)))
            } else if raw.hasPrefix("• ") {
                list.append(String(raw.dropFirst(2)))
            } else {
                flushList()
                result.append(.paragraph(raw))
            }
        }
        flushList()
        return result
    }

    static func attributed(
        _ source: String,
        size: CGFloat,
        weight: Font.Weight,
        color: Color
    ) -> AttributedString {
        guard !source.isEmpty else { return AttributedString() }

        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        options.failurePolicy = .returnPartiallyParsedIfPossible

        var parsed = (try? AttributedString(markdown: source, options: options))
            ?? AttributedString(source)

        let codeColor = Color(red: 0.91, green: 0.75, blue: 0.55)
        for run in parsed.runs {
            var attrs = AttributeContainer()
            let intent = run.inlinePresentationIntent ?? []
            if intent.contains(.code) {
                attrs.font = .system(size: size - 0.5, weight: .medium, design: .monospaced)
                attrs.foregroundColor = codeColor
            } else if intent.contains(.stronglyEmphasized) {
                attrs.font = .system(size: size, weight: .semibold)
                attrs.foregroundColor = Theme.text
            } else if intent.contains(.emphasized) {
                attrs.font = .system(size: size, weight: weight).italic()
                attrs.foregroundColor = color
            } else {
                attrs.font = .system(size: size, weight: weight)
                attrs.foregroundColor = color
            }
            parsed[run.range].mergeAttributes(attrs)
        }
        return parsed
    }
}
