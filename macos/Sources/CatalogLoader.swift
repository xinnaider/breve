import Foundation
import os
import Yams

enum CatalogLoader {
    private static let log = Logger(subsystem: "dev.fordevs.petzinho", category: "catalog")

    enum LoadError: LocalizedError {
        case missingResource(String)
        case empty

        var errorDescription: String? {
            switch self {
            case .missingResource(let name):
                I18n.t("load.missing", language: AppLanguage.fallback, ["file": name])
            case .empty:
                I18n.t("load.empty", language: AppLanguage.fallback)
            }
        }
    }

    static func load(language: AppLanguage, from bundle: Bundle = .main) throws -> Catalog {
        let catalogURL = try url(named: "catalog", extension: "yaml", in: bundle)
        let file = try YAMLDecoder().decode(CatalogFile.self, from: String(contentsOf: catalogURL, encoding: .utf8))
        var types: [StudyType] = []
        var cards: [Card] = []

        for entry in file.types {
            var study = StudyType(
                id: entry.id,
                label: entry.resolvedLabel(language),
                tone: Tone(rawValue: entry.tone) ?? .blue,
                available: entry.available,
                disabledReason: entry.resolvedDisabled(language),
                topics: []
            )
            if entry.available, let source = entry.resolvedSource(language), !source.isEmpty {
                let stem = (source as NSString).deletingPathExtension
                let ext = (source as NSString).pathExtension
                let topicURL = try url(named: stem, extension: ext.isEmpty ? "yaml" : ext, in: bundle)
                log.notice("lang=\(language.rawValue, privacy: .public) source=\(source, privacy: .public) file=\(topicURL.lastPathComponent, privacy: .public)")
                let doc = try YAMLDecoder().decode(TopicFile.self, from: String(contentsOf: topicURL, encoding: .utf8))
                for topic in doc.topics {
                    let available = topic.available ?? true
                    study.topics.append(
                        Topic(id: topic.id, label: topic.label, mark: topic.mark, available: available)
                    )
                    guard available else { continue }
                    for card in topic.cards ?? [] {
                        let teaching = firstNonEmpty(card.explicacao, card.nota)
                        let parsed = CardBody.parse(
                            nota: teaching,
                            codigo: card.codigo,
                            depois: card.depois,
                            exemplo: card.exemplo
                        )
                        cards.append(
                            Card(
                                id: card.id,
                                objectId: study.id,
                                topicId: topic.id,
                                topic: topic.label,
                                mark: topic.mark,
                                frente: card.frente.trimmingCharacters(in: .whitespacesAndNewlines),
                                verso: card.verso.trimmingCharacters(in: .whitespacesAndNewlines),
                                nota: parsed.nota,
                                codigo: parsed.codigo,
                                depois: parsed.depois,
                                mapa: card.mapa.map(ConceptMap.init(file:)),
                                quiz: card.quiz.map(QuizSpec.init(file:))
                            )
                        )
                    }
                }
            }
            types.append(study)
        }

        guard !types.isEmpty else { throw LoadError.empty }
        return Catalog(types: types, cards: cards)
    }

    private static func url(named name: String, extension ext: String, in bundle: Bundle) throws -> URL {
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources") {
            return url
        }
        throw LoadError.missingResource("\(name).\(ext)")
    }

    private static func firstNonEmpty(_ a: String?, _ b: String?) -> String? {
        for raw in [a, b] {
            let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !text.isEmpty { return text }
        }
        return nil
    }
}

private struct CardBody {
    var nota: String
    var codigo: String
    var depois: String

    static func parse(nota: String?, codigo: String?, depois: String?, exemplo: String?) -> CardBody {
        var nota = (nota ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var codigo = (codigo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let depois = (depois ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if nota.isEmpty, codigo.isEmpty,
           let exemplo = exemplo?.trimmingCharacters(in: .whitespacesAndNewlines), !exemplo.isEmpty {
            if looksLikeCode(exemplo) {
                codigo = exemplo
            } else {
                nota = exemplo
            }
        }
        return CardBody(nota: nota, codigo: codigo, depois: depois)
    }

    private static func looksLikeCode(_ text: String) -> Bool {
        text.contains("{")
            || text.contains("class ")
            || text.contains("interface ")
            || text.contains("if (")
            || text.contains("services.")
    }
}

private struct CatalogFile: Decodable {
    var types: [CatalogTypeFile]
}

private struct CatalogTypeFile: Decodable {
    var id: String
    var label: String?
    var labels: [String: String]?
    var tone: String
    var available: Bool
    var source: String?
    var sources: [String: String]?
    var disabledReason: String?
    var disabledReasons: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, label, labels, tone, available, source, sources
        case disabledReason = "disabled_reason"
        case disabledReasons = "disabled_reasons"
    }

    func resolvedLabel(_ language: AppLanguage) -> String {
        pick(labels, language) ?? label ?? id
    }

    func resolvedSource(_ language: AppLanguage) -> String? {
        pick(sources, language) ?? source
    }

    func resolvedDisabled(_ language: AppLanguage) -> String {
        pick(disabledReasons, language) ?? disabledReason ?? ""
    }

    private func pick(_ map: [String: String]?, _ language: AppLanguage) -> String? {
        guard let map else { return nil }
        if let hit = map[language.rawValue], !hit.isEmpty { return hit }
        if let hit = map[AppLanguage.fallback.rawValue], !hit.isEmpty { return hit }
        return nil
    }
}

private struct TopicFile: Decodable {
    var topics: [TopicFileEntry]
}

private struct TopicFileEntry: Decodable {
    var id: String
    var label: String
    var mark: String
    var available: Bool?
    var cards: [CardFile]?
}

private struct CardFile: Decodable {
    var id: String
    var frente: String
    var verso: String
    var nota: String?
    var explicacao: String?
    var codigo: String?
    var depois: String?
    var exemplo: String?
    var mapa: MapFile?
    var quiz: QuizFile?
}

private struct MapFile: Decodable {
    var titulo: String?
    var layout: String?
    var origem: NodeFile?
    var hub: NodeFile?
    var destinos: [NodeFile]?
}

private struct NodeFile: Decodable {
    var label: String
    var kind: String?
}

private struct QuizFile: Decodable {
    var opcoes: [String]
    var certa: Int
}

private extension QuizSpec {
    init(file: QuizFile) {
        self.init(
            options: file.opcoes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            correctIndex: file.certa
        )
    }
}

private extension ConceptMap {
    init(file: MapFile) {
        self.init(
            titulo: (file.titulo ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            layout: ConceptLayout(parsing: file.layout),
            origem: file.origem.map { ConceptNode(label: $0.label, kind: ConceptKind(parsing: $0.kind)) },
            hub: file.hub.map { ConceptNode(label: $0.label, kind: ConceptKind(parsing: $0.kind)) },
            destinos: (file.destinos ?? []).map { ConceptNode(label: $0.label, kind: ConceptKind(parsing: $0.kind)) }
        )
    }
}
