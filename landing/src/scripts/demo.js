const toggle = document.querySelector("#toggle-note");
const note = document.querySelector("#breve-note");
const widget = document.querySelector(".breve-widget");
const screen = document.querySelector(".mac-screen");
const expand = document.querySelector("#expand-note");
const details = document.querySelector("#note-details");
let position = { x: 0, y: 0 }, edge = "right", along = .39, drag = null, suppressClick = false;
const clamp = (n, min, max) => Math.max(min, Math.min(n, max));
function placeNote() {
  const w = screen.clientWidth, h = screen.clientHeight;
  const side = edge === "left" || edge === "right";
  const available = side ? Math.max(position.x - 22, w - position.x - 78) : w - 24;
  note.style.setProperty("--note-width", Math.min(420, available) + "px");
  const nw = note.offsetWidth || Math.min(420, available), nh = note.offsetHeight || 130;
  let x = side ? (position.x > w / 2 ? position.x - nw - 10 : position.x + 66) : position.x + 28 - nw / 2;
  let y = edge === "bottom" ? position.y - nh - 10 : edge === "top" ? position.y + 66 : position.y;
  x = clamp(x, 12, w - nw - 12);
  y = clamp(y, 36, h - nh - 12);
  note.style.left = (x - position.x) + "px";
  note.style.top = (y - position.y) + "px";
  note.style.right = "auto";
  const tip = note.querySelector(".bubble-tip");
  tip.style.left = side ? (position.x > w / 2 ? nw - 8 : -6) + "px" : clamp(position.x + 21 - x, 18, nw - 32) + "px";
  tip.style.top = side ? clamp(position.y + 22 - y, 18, nh - 30) + "px" : edge === "bottom" ? (nh - 8) + "px" : "-6px";
}
function render() {
  widget.style.left = position.x + "px";
  widget.style.top = position.y + "px";
  widget.style.right = "auto";
  placeNote();
}
function anchor() {
  const w = screen.clientWidth, h = screen.clientHeight;
  position = {
    x: edge === "left" ? 12 : edge === "right" ? w - 68 : 12 + along * (w - 80),
    y: edge === "top" ? 42 : edge === "bottom" ? h - 68 : 42 + along * (h - 110),
  };
  render();
}
toggle.addEventListener("click", () => {
  if (suppressClick) { suppressClick = false; return; }
  note.hidden = !note.hidden;
  toggle.setAttribute("aria-expanded", String(!note.hidden));
  toggle.setAttribute("aria-label", note.hidden ? "Abrir informativo do Breve" : "Fechar informativo do Breve");
  placeNote();
});
toggle.addEventListener("pointerdown", event => {
  if (event.button !== 0) return;
  suppressClick = false;
  drag = { id: event.pointerId, x: event.clientX, y: event.clientY, origin: { ...position }, moved: false };
  toggle.setPointerCapture(event.pointerId);
});
toggle.addEventListener("pointermove", event => {
  if (!drag || drag.id !== event.pointerId) return;
  const dx = event.clientX - drag.x, dy = event.clientY - drag.y;
  if (Math.hypot(dx, dy) > 4) drag.moved = true;
  if (!drag.moved) return;
  position.x = clamp(drag.origin.x + dx, 12, screen.clientWidth - 68);
  position.y = clamp(drag.origin.y + dy, 42, screen.clientHeight - 68);
  edge = position.x < screen.clientWidth / 2 ? "left" : "right";
  render();
});
function finish(event) {
  if (!drag || drag.id !== event.pointerId) return;
  suppressClick = drag.moved;
  if (drag.moved) {
    const w = screen.clientWidth, h = screen.clientHeight;
    const distances = { left: position.x, right: w - position.x - 56, top: position.y - 30, bottom: h - position.y - 56 };
    edge = Object.keys(distances).reduce((a, b) => distances[a] < distances[b] ? a : b);
    along = edge === "left" || edge === "right" ? (position.y - 42) / (h - 110) : (position.x - 12) / (w - 80);
    along = clamp(along, 0, 1);
    anchor();
  }
  drag = null;
}
toggle.addEventListener("pointerup", finish);
toggle.addEventListener("pointercancel", finish);
toggle.addEventListener("keydown", event => {
  const edges = { ArrowLeft: "left", ArrowRight: "right", ArrowUp: "top", ArrowDown: "bottom" };
  if (edges[event.key]) { event.preventDefault(); edge = edges[event.key]; along = .5; anchor(); }
});
expand.addEventListener("click", () => {
  details.hidden = !details.hidden;
  expand.setAttribute("aria-expanded", String(!details.hidden));
  expand.setAttribute("aria-label", details.hidden ? "Ver explicação" : "Recolher explicação");
  placeNote();
});
new ResizeObserver(anchor).observe(screen);
anchor();

const modal = document.querySelector("#install-modal");
const copy = document.querySelector("#copy-command");
const copyStatus = document.querySelector("#copy-status");
document.querySelectorAll("[data-install]").forEach(button => button.addEventListener("click", () => modal.showModal()));
document.querySelector(".modal-close").addEventListener("click", () => modal.close());
modal.addEventListener("click", event => {
  const bounds = modal.getBoundingClientRect();
  if (event.target === modal && (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom)) modal.close();
});
copy.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(document.querySelector("#brew-command").textContent.trim());
    copyStatus.textContent = "Comando copiado. Cole no Terminal.";
  } catch {
    copyStatus.textContent = "Selecione o comando e copie com ⌘C.";
  }
});
