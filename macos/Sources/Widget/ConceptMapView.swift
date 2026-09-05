import SwiftUI

struct ConceptMapView: View {
    let map: ConceptMap

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !map.titulo.isEmpty {
                Text(map.titulo)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.label)
            }

            switch map.layout {
            case .compare:
                compareBody
            case .chain:
                chainBody
            case .fanout:
                fanoutBody
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.code, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var fanoutBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let origem = map.origem {
                node(origem)
                if map.hub != nil || !map.destinos.isEmpty {
                    connector
                }
            }
            if let hub = map.hub {
                node(hub)
                if !map.destinos.isEmpty {
                    splitConnector(count: map.destinos.count)
                }
            }
            ForEach(Array(map.destinos.enumerated()), id: \.offset) { index, item in
                node(item)
                if index < map.destinos.count - 1 {
                    connector
                }
            }
        }
    }

    private var chainBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            let steps = [map.origem, map.hub].compactMap { $0 } + map.destinos
            ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                node(item)
                if index < steps.count - 1 {
                    connector
                }
            }
        }
    }

    private var compareBody: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(Array(compareNodes.enumerated()), id: \.offset) { _, item in
                compareTile(item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func compareTile(_ item: ConceptNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.kind.badge)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(item.kind.badgeForeground)
                .padding(.horizontal, 7)
                .frame(height: 18)
                .background(item.kind.badgeBackground, in: Capsule())
            Text(item.label)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(item.kind.stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.kind.badge), \(item.label)")
    }

    private var compareNodes: [ConceptNode] {
        var nodes: [ConceptNode] = []
        if let origem = map.origem { nodes.append(origem) }
        if let hub = map.hub { nodes.append(hub) }
        nodes.append(contentsOf: map.destinos)
        return nodes
    }

    private func node(_ item: ConceptNode) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(item.kind.badge)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(item.kind.badgeForeground)
                .padding(.horizontal, 7)
                .frame(height: 18)
                .background(item.kind.badgeBackground, in: Capsule())
            Text(item.label)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(item.kind.stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.kind.badge), \(item.label)")
    }

    private var connector: some View {
        HStack {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 1, height: 10)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.32))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityHidden(true)
    }

    private func splitConnector(count: Int) -> some View {
        VStack(spacing: 2) {
            connector
            if count > 1 {
                Text("uma fila para cada")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.label)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
            }
        }
        .accessibilityHidden(true)
    }
}

private extension ConceptKind {
    var badgeForeground: Color {
        switch self {
        case .sns: Color(red: 1, green: 0.92, blue: 0.75)
        case .sqs: Color(red: 0.78, green: 0.90, blue: 1)
        case .event: Color.white.opacity(0.82)
        case .service: Color(red: 0.90, green: 0.84, blue: 1)
        }
    }

    var badgeBackground: Color {
        switch self {
        case .sns: Color(red: 251 / 255, green: 146 / 255, blue: 60 / 255).opacity(0.28)
        case .sqs: Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255).opacity(0.28)
        case .event: Color.white.opacity(0.08)
        case .service: Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255).opacity(0.26)
        }
    }

    var stroke: Color {
        switch self {
        case .sns: Color(red: 251 / 255, green: 146 / 255, blue: 60 / 255).opacity(0.28)
        case .sqs: Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255).opacity(0.28)
        case .event: Color.white.opacity(0.06)
        case .service: Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255).opacity(0.22)
        }
    }
}
