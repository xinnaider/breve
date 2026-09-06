#!/usr/bin/env bash
# Compila o Breve neste Mac e copia para Aplicativos.
set -euo pipefail

REPO="${BREVE_REPO:-https://github.com/xinnaider/breve.git}"
DIR="${BREVE_DIR:-$HOME/.local/src/breve}"
SRC_APP="$DIR/app/Breve.app"
DEST_APP="/Applications/Breve.app"
LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

version_ge() {
  [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]
}

die() {
  echo "✗ $1" >&2
  exit 1
}

[[ "$(uname)" == "Darwin" ]] || die "Só macOS."
[[ "$(uname -m)" == "arm64" ]] || die "Só Apple Silicon."
macos_version="$(sw_vers -productVersion 2>/dev/null || echo 0)"
version_ge "$macos_version" "14.0" || die "Requer macOS 14 ou superior (detectado: $macos_version)."
command -v git >/dev/null || die "git não encontrado."
command -v xcodebuild >/dev/null || die "Instale o Xcode."
xcode_path="$(xcode-select -p 2>/dev/null || true)"
[[ "$xcode_path" == *Xcode.app* ]] || die "Selecione o Xcode: sudo xcode-select -s /Applications/Xcode.app"
command -v xcodegen >/dev/null || die "Instale o XcodeGen: brew install xcodegen"

echo "Breve — compilando neste Mac"

if [[ ! -d "$DIR/.git" ]]; then
  echo "→ Baixando código…"
  mkdir -p "$(dirname "$DIR")"
  git clone --depth 1 "$REPO" "$DIR"
else
  echo "→ Atualizando código…"
  git -C "$DIR" pull --ff-only
fi

echo "→ Compilando…"
BREVE_QUIET=1 "$DIR/build.sh"

[[ -d "$SRC_APP" ]] || die "build não gerou $SRC_APP"

echo "→ Instalando em Aplicativos…"
rm -rf "$DEST_APP"
ditto "$SRC_APP" "$DEST_APP"
[[ -x "$LSREG" ]] && "$LSREG" -f "$DEST_APP" || true

echo "Pronto. $DEST_APP"
open "$DEST_APP"
