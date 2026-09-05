import SwiftUI

struct CodeBlock: View {
    let code: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Text(Self.highlighted(code))
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: true)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.code, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(red: 251 / 255, green: 146 / 255, blue: 60 / 255).opacity(0.85))
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 4)
                .allowsHitTesting(false)
        }
    }

    private static let keywords: Set<String> = [
        "class", "interface", "public", "private", "protected", "internal", "static",
        "void", "bool", "int", "string", "var", "if", "else", "return", "new", "using",
        "namespace", "this", "null", "true", "false", "override", "virtual", "async",
        "await", "get", "set", "struct", "enum", "record", "where", "in", "is", "as",
        "try", "catch", "finally", "throw", "for", "foreach", "while", "do", "switch",
        "case", "break", "continue", "default", "const", "readonly", "abstract",
        "sealed", "partial", "base", "typeof", "nameof", "out", "ref", "params",
        "Task", "IActionResult", "HttpPost"
    ]

    private static func highlighted(_ source: String) -> AttributedString {
        var output = AttributedString()
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            output.append(highlightLine(String(line)))
            if index < lines.count - 1 {
                output.append(AttributedString("\n"))
            }
        }
        return output
    }

    private static func highlightLine(_ line: String) -> AttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("//") {
            return attributed(line, color: Color(red: 0.48, green: 0.51, blue: 0.56))
        }

        var result = AttributedString()
        var rest = line
        while !rest.isEmpty {
            if rest.hasPrefix("//") {
                result.append(attributed(rest, color: Color(red: 0.48, green: 0.51, blue: 0.56)))
                break
            }

            if rest.hasPrefix("\"") {
                let end = rest.index(after: rest.startIndex)
                if let close = rest[end...].firstIndex(of: "\"") {
                    let token = String(rest[...close])
                    result.append(attributed(token, color: Color(red: 0.53, green: 0.94, blue: 0.67)))
                    rest = String(rest[rest.index(after: close)...])
                    continue
                }
            }

            if let range = rest.range(of: "^[A-Za-z_][A-Za-z0-9_]*", options: .regularExpression) {
                let token = String(rest[range])
                rest = String(rest[range.upperBound...])
                if keywords.contains(token) {
                    result.append(attributed(token, color: Color(red: 0.77, green: 0.71, blue: 0.99), bold: true))
                } else if token.first?.isUppercase == true {
                    result.append(attributed(token, color: Color(red: 0.58, green: 0.77, blue: 0.99)))
                } else {
                    result.append(attributed(token, color: Color(red: 0.91, green: 0.91, blue: 0.92)))
                }
                continue
            }

            let ch = String(rest.removeFirst())
            result.append(attributed(ch, color: Color.white.opacity(0.55)))
        }
        return result
    }

    private static func attributed(_ text: String, color: Color, bold: Bool = false) -> AttributedString {
        var value = AttributedString(text)
        value.font = bold
            ? .system(size: 12.5, weight: .semibold, design: .monospaced)
            : .system(size: 12.5, weight: .regular, design: .monospaced)
        value.foregroundColor = color
        return value
    }
}
