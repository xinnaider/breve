#!/bin/bash
# Helper destacado: espera o PID do Breve sair, instala, reabre. Timeouts não apagam a versão boa.
set -euo pipefail

SRC="${BREVE_SRC:-}"
DEST="${BREVE_DEST:-/Applications/Breve.app}"
PID="${BREVE_PID:-}"
LOCK="${BREVE_LOCK:-$HOME/Library/Application Support/dev.fordevs.breve/update.lock}"
WAIT_SECS="${BREVE_WAIT_SECS:-90}"
HERE="$(cd "$(dirname "$0")" && pwd)"

INSTALL_APP="${BREVE_INSTALL_APP:-}"
if [[ -z "$INSTALL_APP" ]]; then
  if [[ -f "$HERE/install-app.sh" ]]; then
    INSTALL_APP="$HERE/install-app.sh"
  else
    INSTALL_APP="$HERE/lib/install-app.sh"
  fi
fi

LOCKER="${BREVE_LOCKER:-}"
if [[ -z "$LOCKER" ]]; then
  if [[ -f "$HERE/with-lock.py" ]]; then
    LOCKER="$HERE/with-lock.py"
  else
    LOCKER="$HERE/lib/with-lock.py"
  fi
fi

[[ -n "$SRC" && -d "$SRC" ]] || { echo "✗ BREVE_SRC inválido" >&2; exit 1; }
[[ -f "$INSTALL_APP" ]] || { echo "✗ install-app.sh ausente" >&2; exit 1; }
[[ -f "$LOCKER" ]] || { echo "✗ with-lock.py ausente" >&2; exit 1; }

if [[ -n "$PID" ]]; then
  elapsed=0
  while kill -0 "$PID" 2>/dev/null; do
    if (( elapsed >= WAIT_SECS )); then
      echo "✗ timeout à espera do Breve (pid $PID). Instalação atual preservada." >&2
      exit 1
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
fi

python3 "$LOCKER" "$LOCK" 60 /bin/bash "$INSTALL_APP" --source "$SRC" --dest "$DEST"
/usr/bin/open "$DEST"
