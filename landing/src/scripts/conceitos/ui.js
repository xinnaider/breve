export function prefersReducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

export function scrollToDemo(selector = "[data-note]") {
  const el = document.querySelector(selector);
  el?.scrollIntoView({
    behavior: prefersReducedMotion() ? "auto" : "smooth",
    block: "center",
  });
}

export function wireTryButtons(selector = "[data-note]") {
  document.querySelectorAll("[data-try]").forEach((btn) => {
    btn.addEventListener("click", () => scrollToDemo(selector));
  });
}
