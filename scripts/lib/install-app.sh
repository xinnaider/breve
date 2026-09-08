#!/bin/bash
# Copia um .app para o destino sem rm prévio. Backup + rollback.
# Recupera instalação interrompida (dest ausente + incoming/backup).
set -euo pipefail

usage() {
  echo "uso: install-app.sh --source DIR.app --dest DIR.app" >&2
  exit 2
}

SOURCE=""
DEST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    --lock) shift 2 ;; # lock é do with-lock.py no chamador
    *) usage ;;
  esac
done

[[ -n "$SOURCE" && -n "$DEST" ]] || usage
[[ -d "$SOURCE" ]] || { echo "✗ origem ausente: $SOURCE" >&2; exit 1; }

PARENT="$(dirname "$DEST")"
[[ -w "$PARENT" ]] || { echo "✗ sem permissão de escrita em $PARENT (sem sudo)" >&2; exit 1; }

shopt -s nullglob
incoming=( "${DEST}.incoming."* )
backup=( "${DEST}.backup."* )
if [[ ! -e "$DEST" && ${#incoming[@]} -gt 0 ]]; then
  incoming_i=$(( ${#incoming[@]} - 1 ))
  mv "${incoming[$incoming_i]}" "$DEST" || true
fi
if [[ ! -e "$DEST" && ${#backup[@]} -gt 0 ]]; then
  backup_i=$(( ${#backup[@]} - 1 ))
  mv "${backup[$backup_i]}" "$DEST" || true
fi
shopt -u nullglob

STAMP="$(date +%s)"
STAGING="${DEST}.incoming.${STAMP}"
BACKUP="${DEST}.backup.${STAMP}"
rm -rf "$STAGING"

cleanup_fail() {
  rm -rf "$STAGING" 2>/dev/null || true
}
trap cleanup_fail EXIT

/usr/bin/ditto "$SOURCE" "$STAGING"

if [[ -e "$DEST" ]]; then
  mv "$DEST" "$BACKUP"
fi

if ! mv "$STAGING" "$DEST"; then
  if [[ -e "$BACKUP" ]]; then
    rm -rf "$DEST" 2>/dev/null || true
    if ! mv "$BACKUP" "$DEST"; then
      echo "✗ rollback falhou; backup em $BACKUP" >&2
      exit 1
    fi
  fi
  echo "✗ falha ao mover o app novo; destino restaurado se havia backup" >&2
  exit 1
fi

trap - EXIT
rm -rf "$BACKUP" 2>/dev/null || true

LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
[[ -x "$LSREG" ]] && "$LSREG" -f "$DEST" || true

echo "✓ $DEST"
