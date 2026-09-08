#!/usr/bin/env bash
# Testes do atualizador: versão, erro, rollback, concorrência. Não toca /Applications.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d /tmp/breve-update-tests.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
FAIL=0
ok() { echo "ok  $1"; }
bad() { echo "FAIL $1"; FAIL=$((FAIL + 1)); }

# --- versão / fetch ---
JSON_OK='{"id":99,"tag_name":"v1.0.3","draft":false,"prerelease":false,"tarball_url":"https://api.github.com/repos/xinnaider/breve/tarball/v1.0.3","html_url":"https://github.com/xinnaider/breve/releases/tag/v1.0.3","target_commitish":"abc"}'
eval "$(BREVE_RELEASE_JSON="$JSON_OK" /bin/bash "$ROOT/scripts/lib/fetch-published.sh")"
[[ "$TAG" == "v1.0.3" && "$VERSION" == "1.0.3" ]] && ok "fetch tag estável" || bad "fetch tag estável"

if BREVE_RELEASE_JSON='{"id":1,"tag_name":"v1.0.3","draft":false,"prerelease":true,"tarball_url":"https://api.github.com/repos/xinnaider/breve/tarball/v1.0.3","html_url":"https://github.com/xinnaider/breve/releases/tag/v1.0.3"}' \
  /bin/bash "$ROOT/scripts/lib/fetch-published.sh" >/dev/null 2>&1; then
  bad "fetch recusa prerelease"
else
  ok "fetch recusa prerelease"
fi

if BREVE_RELEASE_JSON='{"id":1,"tag_name":"v1.0.3","draft":false,"prerelease":false,"tarball_url":"https://evil.example/x","html_url":"https://github.com/xinnaider/breve/releases/tag/v1.0.3"}' \
  /bin/bash "$ROOT/scripts/lib/fetch-published.sh" >/dev/null 2>&1; then
  bad "fetch recusa origem"
else
  ok "fetch recusa origem"
fi

# --- transação ---
SRC="$TMP/src.app"
DEST="$TMP/Breve.app"
mkdir -p "$SRC/Contents" "$DEST/Contents"
echo new > "$SRC/Contents/marker"
echo old > "$DEST/Contents/marker"
/bin/bash "$ROOT/scripts/lib/install-app.sh" --source "$SRC" --dest "$DEST"
[[ "$(cat "$DEST/Contents/marker")" == new ]] && ok "install troca conteúdo" || bad "install troca conteúdo"
[[ -e "$DEST" ]] && [[ ! -e "$DEST".backup.* ]] && ok "install não deixa backup" || bad "install não deixa backup"
[[ "$(cat "$DEST/Contents/marker")" == new ]] || true

# falha de origem: dest permanece
echo old2 > "$DEST/Contents/marker"
if /bin/bash "$ROOT/scripts/lib/install-app.sh" --source "$TMP/missing.app" --dest "$DEST" >/dev/null 2>&1; then
  bad "origem ausente falha"
else
  [[ "$(cat "$DEST/Contents/marker")" == old2 ]] && ok "erro não remove dest" || bad "erro não remove dest"
fi

# rollback / recover: dest sumiu, backup existe
rm -rf "$DEST"
mkdir -p "$DEST.backup.1/Contents"
echo recovered > "$DEST.backup.1/Contents/marker"
echo newer > "$SRC/Contents/marker"
/bin/bash "$ROOT/scripts/lib/install-app.sh" --source "$SRC" --dest "$DEST"
[[ "$(cat "$DEST/Contents/marker")" == newer ]] && ok "recover+install após dest ausente" || bad "recover+install após dest ausente"

# incoming interrompido
rm -rf "$DEST"
mkdir -p "$DEST.incoming.9/Contents"
echo incoming > "$DEST.incoming.9/Contents/marker"
echo final > "$SRC/Contents/marker"
/bin/bash "$ROOT/scripts/lib/install-app.sh" --source "$SRC" --dest "$DEST"
[[ "$(cat "$DEST/Contents/marker")" == final ]] && ok "completa incoming e instala" || bad "completa incoming e instala"

# --- concorrência ---
LOCK="$TMP/update.lock"
PYBIN="$(command -v python3)"
python3 "$ROOT/scripts/lib/with-lock.py" "$LOCK" 0 "$PYBIN" -c 'import time; time.sleep(3)' &
SLEEP_PID=$!
sleep 0.2
if python3 "$ROOT/scripts/lib/with-lock.py" "$LOCK" 0 "$PYBIN" -c 'print("should-not-run")' >/dev/null 2>&1; then
  bad "lock NB recusa segundo"
else
  ok "lock NB recusa segundo"
fi
wait "$SLEEP_PID" || true
python3 "$ROOT/scripts/lib/with-lock.py" "$LOCK" 0 "$PYBIN" -c 'pass' && ok "lock libera depois" || bad "lock libera depois"

# --- helper timeout não toca dest ---
KEEP="$TMP/keep.app"
mkdir -p "$KEEP/Contents"
echo keep > "$KEEP/Contents/marker"
sleep 30 &
SLOW=$!
set +e
BREVE_SRC="$SRC" BREVE_DEST="$KEEP" BREVE_PID="$SLOW" BREVE_WAIT_SECS=1 BREVE_LOCK="$TMP/helper.lock" \
  /bin/bash "$ROOT/scripts/apply-update.sh" >/dev/null 2>&1
HELPER=$?
set -e
kill "$SLOW" 2>/dev/null || true
wait "$SLOW" 2>/dev/null || true
[[ "$HELPER" -ne 0 && "$(cat "$KEEP/Contents/marker")" == keep ]] && ok "timeout preserva dest" || bad "timeout preserva dest"

# --- Swift core ---
BIN="$TMP/UpdateCoreFixture"
swiftc -O -parse-as-library \
  -framework Foundation -framework CryptoKit \
  "$HERE/UpdateCoreFixture.swift" \
  "$ROOT"/macos/Sources/Update/*.swift \
  -o "$BIN"
"$BIN" && ok "UpdateCoreFixture" || bad "UpdateCoreFixture"

if [[ "$FAIL" -gt 0 ]]; then
  echo "tests/update: $FAIL falha(s)" >&2
  exit 1
fi
echo "tests/update: ok"
