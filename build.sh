#!/usr/bin/env bash
# Compila Breve.app neste Mac (sem download, sem quarentena de internet).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$ROOT/macos/DerivedData.noindex/Build/Products/Release/Breve.app"
APP_DST="$ROOT/app/Breve.app"
log() { [[ "${BREVE_QUIET:-}" == "1" ]] || echo "$@"; }

command -v xcodegen >/dev/null || {
  echo "Instale o XcodeGen: brew install xcodegen" >&2
  exit 1
}
command -v xcodebuild >/dev/null || {
  echo "Instale o Xcode (não só Command Line Tools)." >&2
  exit 1
}

cd "$ROOT/macos"
log "→ Gerando projeto…"
xcodegen generate
log "→ Compilando Release…"
xcodebuild_args=(
  -scheme Breve
  -configuration Release
  -derivedDataPath ./DerivedData.noindex
  -destination 'platform=macOS'
  build
)
if [[ "${BREVE_QUIET:-}" == "1" ]]; then
  xcodebuild "${xcodebuild_args[@]}" -quiet
else
  xcodebuild "${xcodebuild_args[@]}"
fi
[[ -d "$APP_SRC" ]] || { echo "build não gerou $APP_SRC" >&2; exit 1; }

rm -rf "$APP_DST"
mkdir -p "$ROOT/app"
ditto "$APP_SRC" "$APP_DST"
log "✓ $APP_DST"
