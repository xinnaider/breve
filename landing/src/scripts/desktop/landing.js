import { setupInstall, setupDialog } from "../install.js";

function escapeHtml(text) {
  return String(text).replace(/[&<>"]/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
  }[char]));
}

function inlineMd(text) {
  return escapeHtml(text).replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
}

function splitVerso(verso) {
  const match = String(verso).match(/^\*\*(.+?)\*\*\s*([\s\S]*)$/);
  if (match) return { title: match[1], body: match[2] };
  return { title: verso, body: "" };
}

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

function intersects(a, b) {
  return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
}

export function boot(data) {
  const desk = document.querySelector("[data-desk]");
  const hero = document.querySelector("[data-hero]");
  const showHero = document.querySelector("[data-hero-show]");
  const breve = document.querySelector("[data-breve]");
  const mascot = document.querySelector("[data-toggle-note]");
  const card = document.querySelector("[data-card]");
  const clock = document.querySelector("[data-clock]");
  const installDlg = document.querySelector("[data-install-dialog]");
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const uiFor = (lang) => data.ui[lang] || data.ui.pt;
  const state = {
    lang: "pt",
    format: "both",
    topic: "all",
    index: 0,
    mode: "note",
    hero: "open",
    edge: "right",
    along: 0.42,
    pos: { x: 0, y: 0 },
  };

  const canDrag = () => window.matchMedia("(min-width: 769px)").matches;

  const cards = () => {
    const topics = data.catalog[state.lang] || data.catalog.pt;
    const list = state.topic === "all" ? topics : topics.filter((topic) => topic.id === state.topic);
    return list.flatMap((topic) =>
      topic.cards.map((cardItem) => ({
        ...cardItem,
        topicId: topic.id,
        topicLabel: topic.label,
        mark: topic.mark,
      })),
    );
  };

  const current = () => {
    const list = cards();
    if (!list.length) return null;
    state.index = ((state.index % list.length) + list.length) % list.length;
    return list[state.index];
  };

  const tickClock = () => {
    if (!clock) return;
    clock.dateTime = new Date().toISOString();
    clock.textContent = new Date().toLocaleTimeString("pt-BR", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };
  tickClock();
  window.setInterval(tickClock, 30000);

  const setHero = (next) => {
    state.hero = next;
    hero.hidden = next === "hidden" || next === "min";
    hero.classList.toggle("is-min", next === "min");
    hero.classList.toggle("is-max", next === "max");
    showHero.hidden = next === "open" || next === "max";
    showHero.textContent = next === "min" ? "Restaurar apresentação" : "Mostrar apresentação";
    const maxBtn = hero.querySelector("[data-hero-max]");
    const minBtn = hero.querySelector("[data-hero-min]");
    maxBtn?.setAttribute("aria-pressed", String(next === "max"));
    maxBtn?.setAttribute("aria-label", next === "max" ? "Restaurar apresentação" : "Expandir apresentação");
    minBtn?.setAttribute("aria-pressed", String(next === "min"));
    minBtn?.setAttribute("aria-label", next === "min" ? "Restaurar apresentação" : "Minimizar apresentação");
    if (next === "hidden" || next === "min") showHero.focus();
    place();
  };

  hero.querySelector("[data-hero-close]")?.addEventListener("click", () => setHero("hidden"));
  hero.querySelector("[data-hero-min]")?.addEventListener("click", () => {
    setHero(state.hero === "min" ? "open" : "min");
  });
  hero.querySelector("[data-hero-max]")?.addEventListener("click", () => {
    setHero(state.hero === "max" ? "open" : "max");
  });
  showHero?.addEventListener("click", () => setHero("open"));
  document.querySelectorAll("[data-focus-hero]").forEach(btn => btn.addEventListener("click", () => {
    setHero("open");
    hero.querySelector("h1")?.focus();
  }));

  const modeButtons = () => [...document.querySelectorAll("[data-mode]")];
  const quizOn = () => {
    if (state.format === "quiz") return true;
    if (state.format === "note") return false;
    return state.mode === "quiz";
  };

  const renderSettings = () => {};

  const renderCard = () => {
    const item = current();
    const ui = uiFor(state.lang);
    if (!item) return;
    card.lang = state.lang;
    const showQuiz = quizOn();
    card.querySelector("[data-topic-label]").textContent = item.topicLabel;
    card.querySelector("[data-kind]").textContent = showQuiz ? ui.quiz : ui.informative;
    const noteView = card.querySelector("[data-note-view]");
    const quizView = card.querySelector("[data-quiz-view]");
    noteView.hidden = showQuiz;
    quizView.hidden = !showQuiz;
    modeButtons().forEach((btn) => {
      btn.hidden = state.format !== "both";
      btn.setAttribute("aria-pressed", String(btn.getAttribute("data-mode") === (showQuiz ? "quiz" : "note")));
      btn.textContent = btn.getAttribute("data-mode") === "quiz" ? ui.quiz : ui.note;
    });
    const split = splitVerso(item.verso);
    card.querySelector("[data-note-title]").textContent = split.title;
    card.querySelector("[data-note-body]").textContent = split.body;
    card.querySelector("[data-note-expl]").innerHTML = item.explanation
      .split(/\n\n/)
      .map((para) => `<p>${inlineMd(para)}</p>`)
      .join("");
    const more = card.querySelector("[data-note-more]");
    const noteExpl = card.querySelector("[data-note-expl]");
    noteExpl.hidden = true;
    more.hidden = !item.explanation;
    more.textContent = state.lang === "en" ? "Read more" : "Ver mais";
    card.querySelector("[data-quiz-more]").hidden = true;
    card.querySelector("[data-quiz-title]").textContent = item.frente;
    const options = card.querySelector("[data-options]");
    options.replaceChildren(
      ...item.options.map((label, index) => {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "quiz-opt";
        btn.dataset.option = "";
        btn.dataset.correct = String(index === item.correct);
        btn.textContent = label;
        btn.addEventListener("click", () => answer(index));
        return btn;
      }),
    );
    const explain = card.querySelector("[data-explain]");
    explain.hidden = true;
    explain.removeAttribute("data-result");
    explain.innerHTML = `<strong>${escapeHtml(ui.why)}</strong> ${inlineMd(item.explanation)}`;
    mascot.setAttribute("aria-label", card.hidden ? ui.open : ui.close);
    place();
  };

  const answer = (picked) => {
    const item = current();
    const ui = uiFor(state.lang);
    if (!item) return;
    const buttons = [...card.querySelectorAll("[data-option]")];
    if (buttons.some((btn) => btn.getAttribute("aria-disabled") === "true")) return;
    buttons.forEach((btn, index) => {
      btn.setAttribute("aria-disabled", "true");
      btn.setAttribute("aria-pressed", String(index === picked));
      if (btn.dataset.correct === "true") {
        btn.dataset.reveal = "correct";
        if (!btn.querySelector("[data-correct-label]")) {
          const mark = document.createElement("span");
          mark.dataset.correctLabel = "";
          mark.textContent = ui.correct;
          btn.append(" ", mark);
        }
      }
    });
    const explain = card.querySelector("[data-explain]");
    explain.hidden = false;
    explain.dataset.result = picked === item.correct ? "ok" : "no";
    const toggle = card.querySelector("[data-quiz-more]");
    toggle.hidden = false;
    toggle.textContent = state.lang === "en" ? "Hide explanation" : "Ocultar explicação";
    place();
  };

  const setCardOpen = (open) => {
    card.hidden = !open;
    breve.querySelector(".bubble-tail").hidden = !open;
    mascot.setAttribute("aria-expanded", String(open));
    mascot.setAttribute("aria-label", open ? uiFor(state.lang).close : uiFor(state.lang).open);
    place();
  };

  const heroRect = () => {
    if (hero.hidden) return null;
    const deskBox = desk.getBoundingClientRect();
    const box = hero.getBoundingClientRect();
    return {
      left: box.left - deskBox.left,
      top: box.top - deskBox.top,
      right: box.right - deskBox.left,
      bottom: box.bottom - deskBox.top,
    };
  };

  const placeCard = () => {
    if (card.hidden || !canDrag()) {
      card.style.left = "";
      card.style.top = "";
      return;
    }
    const deskBox = desk.getBoundingClientRect();
    const mascotBox = mascot.getBoundingClientRect();
    const mx = mascotBox.left - deskBox.left;
    const my = mascotBox.top - deskBox.top;
    const width = Math.min(440, desk.clientWidth - 80);
    card.style.width = width + "px";
    const height = card.offsetHeight || 180;
    const maxY = desk.clientHeight - height - 96;
    const side = state.edge === "left" || state.edge === "right";
    let x = side ? (state.edge === "right" ? mx - width - 10 : mx + 66) : mx + 22 - width / 2;
    let y = state.edge === "bottom" ? my - height - 10 : state.edge === "top" ? my + 66 : my - 8;
    x = clamp(x, 12, desk.clientWidth - width - 12);
    y = clamp(y, 40, maxY);
    const hb = heroRect();
    const box = () => ({ left: x, top: y, right: x + width, bottom: y + height });
    if (hb && intersects(box(), hb)) {
      y = clamp(hb.bottom + 12, 40, maxY);
      if (intersects(box(), hb)) x = clamp(hb.right + 12, 12, desk.clientWidth - width - 12);
    }
    card.style.left = x - breve.offsetLeft + "px";
    card.style.top = y - breve.offsetTop + "px";
    const tail = breve.querySelector(".bubble-tail");
    tail.style.left = (state.edge === "right" ? x + width - 8 : x - 6) - breve.offsetLeft + "px";
    tail.style.top = y - breve.offsetTop + 22 + "px";
    tail.hidden = !side;

  };

  const place = () => {
    if (!canDrag()) {
      breve.style.left = "";
      breve.style.top = "";
      card.style.left = "";
      card.style.top = "";
      return;
    }
    const w = desk.clientWidth;
    const h = desk.clientHeight;
    state.pos = {
      x: state.edge === "left" ? 12 : state.edge === "right" ? w - 68 : 12 + state.along * (w - 68),
      y: state.edge === "top" ? 44 : state.edge === "bottom" ? h - 140 : 44 + state.along * (h - 180),
    };
    const hb = heroRect();
    if (hb) {
      const mascotBox = {
        left: state.pos.x,
        top: state.pos.y,
        right: state.pos.x + 44,
        bottom: state.pos.y + 44,
      };
      if (intersects(mascotBox, hb)) {
        if (state.edge === "left") state.pos.y = clamp(hb.bottom + 12, 40, h - 140);
        else if (state.edge === "top") state.pos.x = clamp(hb.right + 12, 12, w - 68);
        else if (state.edge === "bottom") state.pos.x = clamp(Math.max(state.pos.x, hb.right + 12), 12, w - 68);
        else state.pos.y = clamp(Math.max(state.pos.y, hb.bottom + 8), 40, h - 140);
      }
    }
    breve.style.left = state.pos.x + "px";
    breve.style.top = state.pos.y + "px";
    breve.style.right = "auto";
    placeCard();
    document.querySelectorAll("[data-corner]").forEach((btn) => {
      btn.setAttribute("aria-pressed", String(btn.getAttribute("data-corner") === state.edge));
    });
  };

  let drag = null;
  mascot.addEventListener("click", () => {
    if (mascot._skipClick) {
      mascot._skipClick = false;
      return;
    }
    setCardOpen(card.hidden);
  });
  mascot.addEventListener("pointerdown", (event) => {
    if (!canDrag() || event.button !== 0) return;
    drag = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      origin: { ...state.pos },
      moved: false,
    };
    mascot.setPointerCapture(event.pointerId);
  });
  mascot.addEventListener("pointermove", (event) => {
    if (!drag || drag.id !== event.pointerId) return;
    const dx = event.clientX - drag.x;
    const dy = event.clientY - drag.y;
    if (Math.hypot(dx, dy) > 6) drag.moved = true;
    if (!drag.moved) return;
    state.pos.x = clamp(drag.origin.x + dx, 12, desk.clientWidth - 140);
    state.pos.y = clamp(drag.origin.y + dy, 40, desk.clientHeight - 56);
    breve.style.left = state.pos.x + "px";
    breve.style.top = state.pos.y + "px";
    state.edge = state.pos.x < desk.clientWidth / 2 ? "left" : "right";
    placeCard();
  });
  const endDrag = (event) => {
    if (!drag || drag.id !== event.pointerId) return;
    mascot._skipClick = drag.moved;
    if (drag.moved) {
      const w = desk.clientWidth;
      const h = desk.clientHeight;
      const distances = {
        left: state.pos.x,
        right: w - state.pos.x - 44,
        top: state.pos.y - 36,
        bottom: h - state.pos.y - 44,
      };
      state.edge = Object.keys(distances).reduce((a, b) => (distances[a] < distances[b] ? a : b));
      state.along =
        state.edge === "left" || state.edge === "right"
          ? (state.pos.y - 44) / Math.max(1, h - 180)
          : (state.pos.x - 12) / Math.max(1, w - 68);
      state.along = clamp(state.along, 0, 1);
      place();
    }
    drag = null;
  };
  mascot.addEventListener("pointerup", endDrag);
  mascot.addEventListener("pointercancel", endDrag);
  mascot.addEventListener("keydown", (event) => {
    const map = { ArrowLeft: "left", ArrowRight: "right", ArrowUp: "top", ArrowDown: "bottom" };
    if (!map[event.key] || !canDrag()) return;
    event.preventDefault();
    state.edge = map[event.key];
    state.along = 0.5;
    place();
  });

  document.querySelectorAll("[data-corner]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.edge = btn.getAttribute("data-corner");
      state.along = 0.5;
      place();
    });
  });

  modeButtons().forEach((btn) => {
    btn.addEventListener("click", () => {
      state.mode = btn.getAttribute("data-mode");
      renderCard();
      setCardOpen(true);
    });
  });

  document.querySelector("[data-next]")?.addEventListener("click", () => {
    state.index += 1;
    renderCard();
    setCardOpen(true);
  });

  card.querySelector("[data-note-more]")?.addEventListener("click", () => {
    const expl = card.querySelector("[data-note-expl]");
    expl.hidden = !expl.hidden;
    card.querySelector("[data-note-more]").textContent = expl.hidden
      ? (state.lang === "en" ? "Read more" : "Ver mais")
      : (state.lang === "en" ? "Read less" : "Ver menos");
    place();
  });

  document.querySelector("[data-topic]")?.addEventListener("change", (event) => {
    state.topic = event.target.value;
    state.index = 0;
    renderSettings();
    renderCard();
  });
  document.querySelector("[data-lang]")?.addEventListener("change", (event) => {
    const keep = current();
    state.lang = event.target.value;
    const list = cards();
    const found = list.findIndex((item) => item.id === keep?.id);
    state.index = found >= 0 ? found : 0;
    const topicSelect = document.querySelector("[data-topic]");
    if (topicSelect) topicSelect.replaceChildren();
    renderSettings();
    renderCard();
  });
  document.querySelector("[data-format]")?.addEventListener("change", (event) => {
    state.format = event.target.value;
    if (state.format === "quiz") state.mode = "quiz";
    if (state.format === "note") state.mode = "note";
    renderCard();
  });

  document.querySelectorAll("[data-try]").forEach((btn) => {
    btn.addEventListener("click", () => {
      setCardOpen(true);
      const heading = card.querySelector("[data-note-view]:not([hidden]) h2, [data-quiz-view]:not([hidden]) h2");
      heading?.setAttribute("tabindex", "-1");
      heading?.focus();
      if (!reduced) card.scrollIntoView({ block: "nearest", behavior: "smooth" });
      else card.scrollIntoView({ block: "nearest" });
    });
  });

  document.querySelectorAll("[data-install-root]").forEach((root) => setupInstall(root));
  setupDialog(installDlg);

  new ResizeObserver(() => {
    const w = desk.clientWidth;
    const h = desk.clientHeight;
    const heroBox = hero.getBoundingClientRect();
    const deskBox = desk.getBoundingClientRect();
    if (!hero.hidden) {
      const left = heroBox.left - deskBox.left;
      const top = heroBox.top - deskBox.top;
      if (left + heroBox.width > w - 8 && canDrag()) {
        /* hero CSS max-width already clamps */
      }
      if (top < 0) hero.scrollIntoView({ block: "nearest" });
    }
    void h;
    place();
  }).observe(desk);

  card.querySelector("[data-quiz-more]").addEventListener("click", event => {
    const explain = card.querySelector("[data-explain]");
    explain.hidden = !explain.hidden;
    event.currentTarget.textContent = state.lang === "en" ? (explain.hidden ? "Show explanation" : "Hide explanation") : (explain.hidden ? "Ver explicação" : "Ocultar explicação");
    place();
  });
  card.querySelector("[data-note-title]").addEventListener("click", () => card.querySelector("[data-note-more]").click());
  const titlebar = hero.querySelector(".hero-chrome");
  let windowDrag;
  titlebar.addEventListener("pointerdown", event => {
    if (!canDrag() || event.target.closest("button")) return;
    windowDrag = {x:event.clientX,y:event.clientY,left:hero.offsetLeft,top:hero.offsetTop};
    titlebar.setPointerCapture(event.pointerId);
  });
  titlebar.addEventListener("pointermove", event => {
    if (!windowDrag) return;
    hero.style.left = clamp(windowDrag.left + event.clientX - windowDrag.x, 8, desk.clientWidth-hero.offsetWidth-8)+"px";
    hero.style.top = clamp(windowDrag.top + event.clientY - windowDrag.y, 34, Math.max(34,desk.clientHeight-hero.offsetHeight-100))+"px";
    place();
  });
  const finishWindowDrag = () => windowDrag = null;
  titlebar.addEventListener("pointerup", finishWindowDrag);
  titlebar.addEventListener("pointercancel", finishWindowDrag);
  titlebar.addEventListener("dblclick", event => { if (!event.target.closest("button")) setHero(state.hero === "max" ? "open" : "max"); });
  window.addEventListener("resize", () => {
    if (!canDrag()) {hero.style.left="";hero.style.top="";}
    else {hero.style.left=clamp(hero.offsetLeft,8,desk.clientWidth-hero.offsetWidth-8)+"px";hero.style.top=clamp(hero.offsetTop,34,Math.max(34,desk.clientHeight-hero.offsetHeight-100))+"px";}
    place();
  });
  renderSettings();
  const start = cards().findIndex((item) => item.id === "srp-reason");
  state.index = start >= 0 ? start : 0;
  renderCard();
  setCardOpen(true);
  place();
}
