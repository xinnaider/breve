#!/usr/bin/env bash
# Empacota Breve.app (Release) em zip para GitHub Release e generate_appcast.
# Assinatura Apple Developer ID / notarização não entram neste passo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/macos"
xcodegen generate
xcodebuild -scheme Breve -configuration Release -derivedDataPath ./DerivedData.noindex -destination 'platform=macOS' build
APP="$ROOT/macos/DerivedData.noindex/Build/Products/Release/Breve.app"
OUT="${1:-$ROOT/updates/Breve.zip}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT"
python3 - "$APP" "$OUT" <<'PY'
import os, sys
from pathlib import Path
app, zip_path = map(Path, sys.argv[1:])
home = os.environ["HOME"].encode()
hits = []
for path in app.rglob("*"):
    if path.is_file() and home in path.read_bytes():
        hits.append(str(path.relative_to(app)))
if home in zip_path.read_bytes():
    hits.append(str(zip_path))
if hits:
    print("pacote contém o HOME desta máquina:", *hits, sep="\n")
    sys.exit(1)
print("auditoria de caminho local: ok")
PY
echo "zip: $OUT"
ls -lh "$OUT"
shasum -a 256 "$OUT"
echo "Gere o appcast fora deste git; não commite o zip nem a chave EdDSA."
