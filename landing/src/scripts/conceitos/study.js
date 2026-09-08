function bindOptions(scope, explain) {
  scope.querySelectorAll(":scope [data-option]").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (scope.querySelector(":scope [data-option][aria-disabled='true']")) return;
      const ok = btn.getAttribute("data-correct") === "true";
      scope.querySelectorAll(":scope [data-option]").forEach((b) => {
        b.setAttribute("aria-disabled", "true");
        b.setAttribute("aria-pressed", String(b === btn));
        if (b.getAttribute("data-correct") === "true") {
          b.dataset.reveal = "correct";
          if (!b.querySelector("[data-correct-label]")) {
            const mark = document.createElement("span");
            mark.dataset.correctLabel = "";
            mark.textContent = "Certa";
            b.append(" ", mark);
          }
        }
      });
      if (explain) {
        explain.hidden = false;
        explain.dataset.result = ok ? "ok" : "no";
      }
    });
  });
}

export function setupStudy(root) {
  if (!root) return;
  const desk = root.querySelector("[data-desk]");
  const note = root.querySelector("[data-note]");
  const quiz = root.querySelector("[data-quiz]");
  const mascot = root.querySelector("[data-toggle-note]");
  const deskNote = desk?.querySelector("[data-note]") || desk?.querySelector(".study-card");
  const deskQuiz = desk?.querySelector("[data-quiz]");

  const quizModeOn = () =>
    root.querySelector("[data-mode][aria-pressed='true']")?.getAttribute("data-mode") === "quiz";

  const setDeskOpen = (open) => {
    mascot?.setAttribute("aria-expanded", String(open));
    if (!open) {
      if (deskNote) deskNote.hidden = true;
      if (deskQuiz) deskQuiz.hidden = true;
      return;
    }
    const showQuiz = Boolean(deskQuiz && quizModeOn());
    if (deskNote) deskNote.hidden = showQuiz;
    if (deskQuiz) deskQuiz.hidden = !showQuiz;
  };

  mascot?.addEventListener("click", () => {
    setDeskOpen(mascot.getAttribute("aria-expanded") !== "true");
  });

  root.querySelectorAll("[data-mode]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const mode = btn.getAttribute("data-mode");
      root.querySelectorAll("[data-mode]").forEach((b) => b.setAttribute("aria-pressed", String(b === btn)));
      if (mode === "quiz") {
        if (note) note.hidden = true;
        if (quiz) quiz.hidden = false;
      } else {
        if (quiz) quiz.hidden = true;
        if (note) note.hidden = false;
      }
      setDeskOpen(true);
    });
  });

  root.querySelectorAll("[data-corner]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const edge = btn.getAttribute("data-corner");
      if (desk && edge) desk.dataset.edge = edge;
      root.querySelectorAll("[data-corner]").forEach((b) => b.setAttribute("aria-pressed", String(b === btn)));
    });
  });

  const packs = [...root.querySelectorAll("[data-quiz-pack]")];
  if (packs.length) {
    packs.forEach((packEl) => bindOptions(packEl, packEl.querySelector("[data-explain]")));
  } else {
    const quizRoot = root.querySelector("[data-quiz], [data-quiz-inline]") || root;
    bindOptions(quizRoot, quizRoot.querySelector("[data-explain]"));
  }

  let pack = 0;
  const showPack = (i) => {
    packs.forEach((el, idx) => {
      el.hidden = idx !== i;
    });
    packs[i]?.querySelectorAll("[data-option]").forEach((b) => {
      b.removeAttribute("aria-disabled");
      b.removeAttribute("aria-pressed");
      delete b.dataset.reveal;
      b.querySelector("[data-correct-label]")?.remove();
    });
    const explain = packs[i]?.querySelector("[data-explain]");
    if (explain) explain.hidden = true;
  };
  root.querySelector("[data-next]")?.addEventListener("click", () => {
    if (!packs.length) return;
    pack = (pack + 1) % packs.length;
    showPack(pack);
  });
}
