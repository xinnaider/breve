import AppKit
import SwiftUI

enum Theme {
    static let bubble = Color(red: 17 / 255, green: 17 / 255, blue: 19 / 255)
    static let sheet = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let code = Color(red: 11 / 255, green: 11 / 255, blue: 13 / 255)
    static let text = Color.white.opacity(0.92)
    static let muted = Color.white.opacity(0.58)
    static let label = Color.white.opacity(0.4)

    static let face: CGFloat = 56
    static let bubbleWidth: CGFloat = 300
    static let bubbleDeepWidth: CGFloat = 520
    static let gap: CGFloat = 10
    static let edge: CGFloat = 12
    static let chevron: CGFloat = 32
    static let answerMaxHeight: CGFloat = 380
    static let bubblePadX: CGFloat = 16
    static let petPadTop: CGFloat = 8
    static let petPadBottom: CGFloat = 24
    static let petPadEdge: CGFloat = 4
    static let shadowBloom: CGFloat = 8

    static func clusterInsets(for edge: DockEdge) -> EdgeInsets {
        switch edge {
        case .right:
            EdgeInsets(top: petPadTop, leading: shadowBloom, bottom: petPadBottom, trailing: petPadEdge)
        case .left:
            EdgeInsets(top: petPadTop, leading: petPadEdge, bottom: petPadBottom, trailing: shadowBloom)
        case .top:
            EdgeInsets(top: petPadEdge, leading: shadowBloom, bottom: petPadBottom, trailing: shadowBloom)
        case .bottom:
            EdgeInsets(top: shadowBloom, leading: shadowBloom, bottom: petPadEdge, trailing: shadowBloom)
        }
    }

    static func questionWidth(_ text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let plain = markdownPlain(text)
        let oneLine = ceil((plain as NSString).size(withAttributes: [.font: font]).width)
        let minW: CGFloat = 260
        let maxW: CGFloat = 520
        return min(maxW, max(minW, oneLine + 6))
    }

    static func markdownPlain(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "*", with: "")
    }

    static func expandedBubbleInnerWidth(question: String, card: Card) -> CGFloat {
        let questionInner = questionWidth(question)
        if card.hasCode {
            return max(questionInner, bubbleDeepWidth)
        }
        if card.hasMap || card.quiz != nil {
            return max(questionInner, 360)
        }
        return max(questionInner, 320)
    }

    static func estimatedPanelSize(
        card: Card,
        deep: Bool,
        edge: DockEdge = .right,
        headline: String? = nil,
        quizVisible: Bool = false
    ) -> CGSize {
        let title = headline ?? card.frente
        let inner = (deep || quizVisible)
            ? expandedBubbleInnerWidth(question: title, card: card)
            : questionWidth(title)
        let bubbleW = inner + bubblePadX * 2
        let insets = clusterInsets(for: edge)
        let width = face + gap + bubbleW + insets.leading + insets.trailing
        let body: CGFloat
        if deep {
            body = min(answerMaxHeight + 180, 560)
        } else if quizVisible {
            let rows = CGFloat(max(2, card.quiz?.options.count ?? 3))
            body = 150 + rows * 58
        } else {
            body = 180
        }
        return CGSize(width: width, height: body + insets.top + insets.bottom)
    }

    static let hideDuration: TimeInterval = 10
    static let pebbleDuration: TimeInterval = 18
    static let appearCenter: TimeInterval = 30 * 60
    static let appearJitter: Double = 0.2

    static func toneForeground(_ tone: Tone) -> Color {
        switch tone {
        case .blue: Color(red: 191 / 255, green: 219 / 255, blue: 254 / 255)
        case .amber: Color(red: 253 / 255, green: 230 / 255, blue: 138 / 255)
        case .violet: Color(red: 221 / 255, green: 214 / 255, blue: 254 / 255)
        }
    }

    static func toneBackground(_ tone: Tone) -> Color {
        switch tone {
        case .blue: Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255).opacity(0.18)
        case .amber: Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255).opacity(0.18)
        case .violet: Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255).opacity(0.16)
        }
    }
}
