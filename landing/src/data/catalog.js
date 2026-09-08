import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

function findContentDir() {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const candidates = [
    path.resolve(process.cwd(), "../content"),
    path.resolve(process.cwd(), "content"),
    path.resolve(here, "../../../content"),
    path.resolve(here, "../../../../content"),
  ];
  for (const dir of candidates) {
    if (existsSync(path.join(dir, "development.pt.yaml"))) return dir;
  }
  throw new Error("Catálogo YAML não encontrado (content/development.pt.yaml).");
}

const contentDir = findContentDir();

function unquote(value) {
  const text = value.trim();
  if (text.startsWith('"') && text.endsWith('"')) {
    return text
      .slice(1, -1)
      .replace(/\\"/g, '"')
      .replace(/\\n/g, "\n");
  }
  return text;
}

function parseDevelopment(source) {
  const lines = source.replace(/\r\n/g, "\n").split("\n");
  const topics = [];
  let topic = null;
  let card = null;
  let mode = null;
  const expl = [];

  const finishExpl = () => {
    if (card && mode === "explicacao") {
      card.explanation = expl.join("\n").replace(/\n{3,}/g, "\n\n").trim();
      expl.length = 0;
      mode = null;
    }
  };

  const finishCard = () => {
    finishExpl();
    if (topic && card?.id && card.frente) {
      topic.cards.push(card);
    }
    card = null;
    mode = null;
  };

  const finishTopic = () => {
    finishCard();
    if (topic?.id && topic.cards.length) topics.push(topic);
    topic = null;
  };

  for (const raw of lines) {
    if (mode === "explicacao") {
      if (/^        quiz:/.test(raw) || /^      - id:/.test(raw) || /^  - id:/.test(raw)) {
        finishExpl();
      } else {
        expl.push(raw.replace(/^          /, ""));
        continue;
      }
    }

    const topicMatch = raw.match(/^  - id:\s*(.+)$/);
    if (topicMatch) {
      finishTopic();
      topic = { id: unquote(topicMatch[1]), label: "", mark: "", cards: [] };
      continue;
    }

    if (topic && !card && raw.match(/^    label:\s*(.+)$/)) {
      topic.label = unquote(raw.slice(raw.indexOf(":") + 1));
      continue;
    }
    if (topic && !card && raw.match(/^    mark:\s*(.+)$/)) {
      topic.mark = unquote(raw.slice(raw.indexOf(":") + 1));
      continue;
    }

    const cardMatch = raw.match(/^      - id:\s*(.+)$/);
    if (cardMatch) {
      finishCard();
      card = {
        id: unquote(cardMatch[1]),
        frente: "",
        verso: "",
        explanation: "",
        options: [],
        correct: 0,
      };
      continue;
    }

    if (!card) continue;

    if (/^        frente:\s*/.test(raw)) {
      card.frente = unquote(raw.replace(/^        frente:\s*/, ""));
      continue;
    }
    if (/^        verso:\s*/.test(raw)) {
      card.verso = unquote(raw.replace(/^        verso:\s*/, ""));
      continue;
    }
    if (/^        explicacao:\s*\|/.test(raw)) {
      mode = "explicacao";
      expl.length = 0;
      continue;
    }
    if (/^          certa:\s*/.test(raw)) {
      card.correct = Number(unquote(raw.replace(/^          certa:\s*/, ""))) || 0;
      continue;
    }
    if (/^            - /.test(raw)) {
      card.options.push(unquote(raw.replace(/^            - /, "")));
    }
  }

  finishTopic();
  return topics;
}

function loadLang(file) {
  return parseDevelopment(readFileSync(path.join(contentDir, file), "utf8"));
}

export const CATALOG = {
  pt: loadLang("development.pt.yaml"),
  en: loadLang("development.en.yaml"),
};

export const UI = {
  pt: {
    note: "Nota",
    quiz: "Questão",
    both: "Os dois",
    next: "Próximo conteúdo",
    why: "Por quê.",
    correct: "Certa",
    lang: "Idioma",
    format: "Formato",
    topic: "Tema",
    informative: "Informativo",
    more: "Ver explicação",
    less: "Recolher explicação",
    open: "Abrir o Breve",
    close: "Fechar o cartão",
    move: "Mover o mascote",
    left: "Esquerda",
    right: "Direita",
    top: "Cima",
    bottom: "Baixo",
  },
  en: {
    note: "Note",
    quiz: "Question",
    both: "Both",
    next: "Next",
    why: "Why.",
    correct: "Correct",
    lang: "Language",
    format: "Format",
    topic: "Topic",
    informative: "Note",
    more: "Show explanation",
    less: "Hide explanation",
    open: "Open Breve",
    close: "Close the card",
    move: "Move the mascot",
    left: "Left",
    right: "Right",
    top: "Top",
    bottom: "Bottom",
  },
};
