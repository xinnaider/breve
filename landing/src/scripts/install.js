import { INSTALL_CMD } from "../data/install.js";

function isMacOS() {
  const ua = navigator.userAgent || "";
  if (/iPhone|iPad|iPod/.test(ua)) return false;
  return /Macintosh|Mac OS X/.test(ua);
}

export function setupInstall(root) {
  if (!root) return;
  const field = root.querySelector("[data-install-cmd]");
  const button = root.querySelector("[data-copy]");
  const status = root.querySelector("[data-copy-status]");
  const nonMac = root.querySelector("[data-nonmac]");
  if (field) field.value = INSTALL_CMD;
  if (nonMac) nonMac.hidden = isMacOS();

  field?.addEventListener("focus", () => field.select());
  field?.addEventListener("click", () => field.select());

  const setCopied = () => {
    if (!button || !status) return;
    button.textContent = "Copiado";
    button.setAttribute("aria-label", "Copiado");
    status.textContent = "";
    window.setTimeout(() => {
      button.textContent = "Copiar comando";
      button.setAttribute("aria-label", "Copiar comando");
    }, 1800);
  };

  const fail = () => {
    if (status) {
      status.textContent = "Não foi possível copiar. Selecione o comando e copie manualmente.";
    }
    field?.focus();
    field?.select();
  };

  button?.addEventListener("click", async () => {
    if (button.hasAttribute("data-force-fail")) {
      fail();
      return;
    }
    try {
      await navigator.clipboard.writeText(INSTALL_CMD);
      setCopied();
    } catch {
      fail();
    }
  });
}

export function setupDialog(dialog) {
  if (!dialog) return;
  let last = null;
  document.querySelectorAll("[data-open-install]").forEach((btn) => {
    btn.addEventListener("click", () => {
      last = btn;
      dialog.showModal();
      const focusable =
        dialog.querySelector("[data-dialog-focus]") || dialog.querySelector("button, textarea, a");
      focusable?.focus();
    });
  });
  dialog.querySelectorAll("[data-close-install]").forEach((btn) => {
    btn.addEventListener("click", () => dialog.close());
  });
  dialog.addEventListener("close", () => last?.focus());
}
