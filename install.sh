#!/usr/bin/env bash
# Instala o Breve a partir da release GitHub estável (tag), compilando neste Mac.
# Autocontido: curl|bash não precisa do restante do clone.
# Não faz git pull de main. Não apaga /Applications/Breve.app antes de copiar.
# Não usa sudo/chmod no destino. Sem lock do flock(1) (ausente no macOS).
set -euo pipefail

REPO_SLUG="xinnaider/breve"
DEST_APP="${BREVE_DEST:-/Applications/Breve.app}"
CACHE="${BREVE_CACHE:-$HOME/Library/Caches/dev.fordevs.breve/src.noindex}"
LOCK="${BREVE_LOCK:-$HOME/Library/Application Support/dev.fordevs.breve/update.lock}"
API="${BREVE_RELEASE_API:-https://api.github.com/repos/${REPO_SLUG}/releases/latest}"
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || HERE=""
LOCAL=0
REQUESTED_TAG="${BREVE_TAG:-}"

# BEGIN BREVE TERMINAL UI — presentation only; keep curl|bash self-contained.
BREVE_UI_ACCENT="" BREVE_UI_DIM="" BREVE_UI_BOLD="" BREVE_UI_RESET="" BREVE_UI_GREEN=""
if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR+x}" ]]; then
  BREVE_UI_ACCENT=$'\033[38;5;209m'
  BREVE_UI_DIM=$'\033[38;5;245m'
  BREVE_UI_BOLD=$'\033[1m'
  BREVE_UI_GREEN=$'\033[38;5;114m'
  BREVE_UI_RESET=$'\033[0m'
fi
BREVE_UI_STEP=""
breve_ui_header() {
  printf '\n'
  if [[ "${COLUMNS:-80}" -ge 64 ]]; then
    printf '  %s%s%s\n' "$BREVE_UI_ACCENT" '                  _                         ' "$BREVE_UI_RESET"
    printf '  %s%s%s\n' "$BREVE_UI_ACCENT" '   .--------.    | |__  _ __ _____   _____  ' "$BREVE_UI_RESET"
    printf '  %s%s%s\n' "$BREVE_UI_ACCENT" '  /  o    o  \   |  _ \| __/ _ \ \ / / _ \ ' "$BREVE_UI_RESET"
    printf '  %s%s%s\n' "$BREVE_UI_ACCENT" '  |    __    |   | |_) | | |  __/\ V /  __/ ' "$BREVE_UI_RESET"
    printf '  %s%s%s\n' "$BREVE_UI_ACCENT" '   `--------´   |_.__/|_|  \___| \_/ \___| ' "$BREVE_UI_RESET"
  else
    printf '  %s%sbreve%s  [ o_o ]\n' "$BREVE_UI_ACCENT" "$BREVE_UI_BOLD" "$BREVE_UI_RESET"
  fi
  printf '\n  %sUm pequeno espaço para aprender.%s\n' "$BREVE_UI_BOLD" "$BREVE_UI_RESET"
  printf '  %sVamos preparar o Breve no seu Mac.%s\n\n' "$BREVE_UI_DIM" "$BREVE_UI_RESET"
}
breve_ui_step() {
  BREVE_UI_STEP="$2"
  printf '\n  %s%s[%s/5]%s %s%s%s\n' "$BREVE_UI_ACCENT" "$BREVE_UI_BOLD" "$1" "$BREVE_UI_RESET" "$BREVE_UI_BOLD" "$2" "$BREVE_UI_RESET"
  printf '        %s%s%s\n' "$BREVE_UI_DIM" "$3" "$BREVE_UI_RESET"
}
breve_ui_done() {
  printf '        %s+%s %s\n' "$BREVE_UI_GREEN" "$BREVE_UI_RESET" "$1"
}
breve_ui_detail() {
  printf '        %s%s%s\n' "$BREVE_UI_DIM" "$1" "$BREVE_UI_RESET"
}
breve_ui_error() {
  printf '\n  %s%s! Não foi possível continuar.%s\n' "$BREVE_UI_ACCENT" "$BREVE_UI_BOLD" "$BREVE_UI_RESET" >&2
  [[ -z "$BREVE_UI_STEP" ]] || printf '    Etapa: %s\n' "$BREVE_UI_STEP" >&2
  printf '    %s\n\n' "$1" >&2
}
breve_ui_finish() {
  printf '\n  %s%s+ Tudo pronto. O Breve é seu.%s\n' "$BREVE_UI_GREEN" "$BREVE_UI_BOLD" "$BREVE_UI_RESET"
  printf '    Versão %s · instalado em Aplicativos.\n' "$1"
  printf '    %sUma pausa. Uma ideia nova.%s\n\n' "$BREVE_UI_DIM" "$BREVE_UI_RESET"
}
# END BREVE TERMINAL UI

die() { breve_ui_error "$1"; exit 1; }

version_ge() {
  [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]
}

hold_lock() {
  exec 8< <(python3 - "$LOCK" <<'PY'
import fcntl, os, signal, sys
path = sys.argv[1]
parent = os.path.dirname(os.path.abspath(path))
if parent:
    os.makedirs(parent, exist_ok=True)
fd = os.open(path, os.O_CREAT | os.O_RDWR, 0o644)
try:
    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    sys.exit(1)
sys.stdout.write("ok\n")
sys.stdout.flush()
signal.pause()
PY
)
  LOCK_PY_PID=$!
  if ! IFS= read -r lock_reply <&8; then
    die "Atualização já em andamento."
  fi
  [[ "$lock_reply" == ok ]] || die "Atualização já em andamento."
  trap 'kill '"$LOCK_PY_PID"' 2>/dev/null || true' EXIT
}

marketing_version() {
  python3 - "$1" <<'PY'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
match = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', text)
print(match.group(1) if match else "")
PY
}

parse_release() {
  python3 - "$1" <<'PY'
import json, re, sys, shlex
from urllib.parse import urlparse
data = json.loads(sys.argv[1])
if data.get("draft") or data.get("prerelease"):
    sys.exit("release não é estável")
tag = data.get("tag_name") or ""
if not re.fullmatch(r"v?[0-9]+\.[0-9]+\.[0-9]+", tag):
    sys.exit("tag inválida")
tarball = data.get("tarball_url") or ""
parsed = urlparse(tarball)
host = (parsed.hostname or "").lower()
if parsed.scheme != "https" or host not in {"api.github.com", "codeload.github.com", "github.com"}:
    sys.exit("origem do tarball recusada")
if not re.match(r"^/(?:repos/)?xinnaider/breve(?:/|$)", parsed.path):
    sys.exit("repositório inesperado")
version = tag[1:] if tag.startswith("v") else tag
print(f"TAG={tag}")
print(f"VERSION={version}")
print("TARBALL=" + shlex.quote(tarball))
PY
}

install_bundle() {
  local source="$1"
  local dest="$2"
  local parent stamp staging backup
  parent="$(dirname "$dest")"
  [[ -w "$parent" ]] || die "Sem permissão de escrita em $parent (sem sudo)."
  stamp="$(date +%s)"
  staging="${dest}.incoming.${stamp}"
  backup="${dest}.backup.${stamp}"
  rm -rf "$staging"
  /usr/bin/ditto "$source" "$staging"
  if [[ -e "$dest" ]]; then
    mv "$dest" "$backup"
  fi
  if ! mv "$staging" "$dest"; then
    if [[ -e "$backup" ]]; then
      rm -rf "$dest" 2>/dev/null || true
      mv "$backup" "$dest"
    fi
    die "Falha ao mover o app novo; destino restaurado se havia backup."
  fi
  rm -rf "$backup" 2>/dev/null || true
  local lsreg="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
  [[ -x "$lsreg" ]] && "$lsreg" -f "$dest" || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local) LOCAL=1; shift ;;
    --tag) REQUESTED_TAG="${2:-}"; shift 2 ;;
    *) die "uso: install.sh [--local] [--tag vX.Y.Z]" ;;
  esac
done

breve_ui_header
breve_ui_step 1 "Preparar" "Conferindo o que precisamos para começar."

[[ "$(uname)" == "Darwin" ]] || die "Só macOS."
[[ "$(uname -m)" == "arm64" ]] || die "Só Apple Silicon."
macos_version="$(sw_vers -productVersion 2>/dev/null || echo 0)"
version_ge "$macos_version" "14.0" || die "Requer macOS 14 ou superior (detectado: $macos_version)."
command -v python3 >/dev/null || die "python3 não encontrado."
command -v xcodebuild >/dev/null || die "Instale o Xcode."
xcode_path="$(xcode-select -p 2>/dev/null || true)"
[[ "$xcode_path" == *Xcode.app* ]] || die "Selecione o Xcode: sudo xcode-select -s /Applications/Xcode.app"
command -v xcodegen >/dev/null || die "Instale o XcodeGen: brew install xcodegen"
[[ -w "$(dirname "$DEST_APP")" ]] || die "Sem permissão de escrita em $(dirname "$DEST_APP") (sem sudo)."

hold_lock
breve_ui_done "Mac e ferramentas prontos."

breve_ui_step 2 "Encontrar o Breve" "Preparando o código da versão escolhida."
ROOT=""
TAG=""
VERSION=""

if [[ "$LOCAL" == 1 ]]; then
  [[ -n "$HERE" && -f "$HERE/build.sh" ]] || die "--local exige o repositório (build.sh)."
  ROOT="$HERE"
  VERSION="$(marketing_version "$ROOT/macos/project.yml")"
  [[ -n "$VERSION" ]] || die "MARKETING_VERSION ausente no checkout local."
  breve_ui_detail "Código local · versão $VERSION"
else
  breve_ui_detail "Buscando a versão estável no GitHub…"
  JSON="$(/usr/bin/curl -fsSL -A "Breve-installer (dev.fordevs.breve)" "$API")"
  RELEASE_VALUES="$(parse_release "$JSON")" || die "Release inválida."
  eval "$RELEASE_VALUES"
  [[ -n "${TAG:-}" && -n "${VERSION:-}" && -n "${TARBALL:-}" ]] || die "Não li a release publicada."
  if [[ -n "$REQUESTED_TAG" ]]; then
    [[ "$REQUESTED_TAG" == "$TAG" || "$REQUESTED_TAG" == "v$VERSION" || "$REQUESTED_TAG" == "$VERSION" ]] \
      || die "A tag pedida ($REQUESTED_TAG) não é a release estável atual ($TAG)."
  fi
  breve_ui_detail "Versão $TAG encontrada. Baixando…"
  WORK="$CACHE/$VERSION"
  rm -rf "$WORK"
  mkdir -p "$WORK"
  ARCHIVE="$WORK/src.tar.gz"
  /usr/bin/curl -fsSL -A "Breve-installer (dev.fordevs.breve)" "$TARBALL" -o "$ARCHIVE"
  [[ -s "$ARCHIVE" ]] || die "Download do código vazio."
  DIGEST="$(/usr/bin/shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
  [[ ${#DIGEST} -eq 64 ]] || die "SHA-256 do tarball inválido."
  [[ "${BREVE_VERBOSE:-0}" != 1 ]] || breve_ui_detail "Origem: $TARBALL"
  [[ "${BREVE_VERBOSE:-0}" != 1 ]] || breve_ui_detail "SHA-256: $DIGEST"
  tar -xzf "$ARCHIVE" -C "$WORK"
  ROOT="$(find "$WORK" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$ROOT" && -f "$ROOT/build.sh" ]] || die "Tarball sem build.sh."
  FOUND="$(marketing_version "$ROOT/macos/project.yml")"
  [[ "$FOUND" == "$VERSION" ]] || die "MARKETING_VERSION ($FOUND) ≠ tag ($VERSION)."
fi

breve_ui_done "Código preparado."
breve_ui_step 3 "Dar vida ao Breve" "Compilando neste Mac. Pode levar alguns minutos."
BREVE_QUIET=1 "$ROOT/build.sh"
SRC_APP="$ROOT/app/Breve.app"
[[ -d "$SRC_APP" ]] || die "build não gerou $SRC_APP"
ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SRC_APP/Contents/Info.plist")"
MARKETING="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SRC_APP/Contents/Info.plist")"
[[ "$ID" == "dev.fordevs.breve" ]] || die "bundle id inesperado: $ID"
[[ "$MARKETING" == "$VERSION" ]] || die "versão compilada ($MARKETING) ≠ publicada ($VERSION)"

/usr/bin/codesign --verify --deep --strict "$SRC_APP" || die "Assinatura do app inválida."

breve_ui_done "Compilação concluída e versão conferida."
breve_ui_step 4 "Encontrar seu lugar" "Instalando o Breve em Aplicativos."
# Stop only the executable at this destination before swapping its bundle.
python3 - "$DEST_APP/Contents/MacOS/Breve" <<'PY_STOP'
import os, signal, subprocess, sys, time
expected = os.path.realpath(sys.argv[1])
rows = subprocess.check_output(["/bin/ps", "-axo", "pid=,comm="], text=True).splitlines()
pids = []
for row in rows:
    parts = row.strip().split(None, 1)
    if len(parts) == 2 and os.path.realpath(parts[1]) == expected:
        pid = int(parts[0])
        try:
            os.kill(pid, signal.SIGTERM)
            pids.append(pid)
        except ProcessLookupError:
            pass
for _ in range(100):
    alive = []
    for pid in pids:
        try:
            os.kill(pid, 0)
            alive.append(pid)
        except ProcessLookupError:
            pass
    if not alive:
        break
    pids = alive
    time.sleep(0.1)
else:
    sys.exit("Breve ainda está encerrando. Instalação anterior preservada; tente novamente.")
PY_STOP

if [[ -f "$ROOT/scripts/lib/install-app.sh" ]]; then
  /bin/bash "$ROOT/scripts/lib/install-app.sh" --source "$SRC_APP" --dest "$DEST_APP" >/dev/null
else
  install_bundle "$SRC_APP" "$DEST_APP"
fi

if [[ "$LOCAL" != 1 ]]; then
  rm -rf "$ROOT/app/Breve.app"
fi

breve_ui_done "Instalado. Suas preferências continuam com você."
breve_ui_step 5 "Conhecer o Breve" "Abrindo o aplicativo…"
open "$DEST_APP"
breve_ui_finish "$VERSION"
