import Foundation

enum Tone: String, Codable, Sendable {
    case blue, amber, violet
}

struct StudyType: Identifiable, Hashable, Sendable {
    var id: String
    var label: String
    var tone: Tone
    var available: Bool
    var disabledReason: String
    var topics: [Topic]
}

struct Topic: Identifiable, Hashable, Sendable {
    var id: String
    var label: String
    var mark: String
    var available: Bool
}

struct Card: Identifiable, Hashable, Sendable {
    var id: String
    var objectId: String
    var topicId: String
    var topic: String
    var mark: String
    var frente: String
    var verso: String
    var nota: String
    var codigo: String
    var depois: String
    var mapa: ConceptMap?
    var quiz: QuizSpec?

    var hasCode: Bool { !codigo.isEmpty }
    var hasMap: Bool {
        guard let mapa else { return false }
        return mapa.origem != nil || mapa.hub != nil || !mapa.destinos.isEmpty
    }
    var hasExtra: Bool { !nota.isEmpty || hasCode || hasMap || !depois.isEmpty }
    var needsWide: Bool { hasCode || hasMap }
}

struct QuizSpec: Hashable, Sendable {
    var options: [String]
    var correctIndex: Int
}

struct QuizOption: Identifiable, Hashable, Sendable {
    var id: String
    var text: String
    var correct: Bool
}

enum TipKind: String, Equatable, Sendable {
    case quiz
    case info
}

enum ConceptKind: String, Hashable, Sendable {
    case event, sns, sqs, service

    init(parsing raw: String?) {
        switch (raw ?? "").lowercased() {
        case "sns", "topic", "topico", "tópico": self = .sns
        case "sqs", "queue", "fila": self = .sqs
        case "service", "servico", "serviço": self = .service
        default: self = .event
        }
    }

    var badge: String {
        switch self {
        case .sns: "SNS"
        case .sqs: "SQS"
        case .event: "evento"
        case .service: "serviço"
        }
    }
}

enum ConceptLayout: String, Hashable, Sendable {
    case fanout, compare, chain

    init(parsing raw: String?) {
        switch (raw ?? "").lowercased() {
        case "compare", "lado": self = .compare
        case "chain", "fluxo": self = .chain
        default: self = .fanout
        }
    }
}

struct ConceptNode: Hashable, Sendable {
    var label: String
    var kind: ConceptKind
}

struct ConceptMap: Hashable, Sendable {
    var titulo: String
    var layout: ConceptLayout
    var origem: ConceptNode?
    var hub: ConceptNode?
    var destinos: [ConceptNode]
}

struct Catalog: Sendable {
    var types: [StudyType]
    var cards: [Card]

    func type(id: String) -> StudyType? {
        types.first { $0.id == id }
    }

    func topic(typeId: String, topicId: String) -> Topic? {
        type(id: typeId)?.topics.first { $0.id == topicId }
    }
}

struct TypeSelection: Hashable, Sendable {
    var on: Bool
    var topics: Set<String>
}
