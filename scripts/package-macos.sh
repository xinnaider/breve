#!/usr/bin/env bash
# Empacota Breve.app em zip para um futuro appcast Sparkle.
# Nao assina Developer ID nem notoriza. Nao publique como instalador de usuario
# ate existir identidade Apple e um enclosure EdDSA no appcast.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/macos"
xcodegen generate
xcodebuild -scheme Petzinho -configuration Release -derivedDataPath ./DerivedData -destination 'platform=macOS' build
APP="$ROOT/macos/DerivedData/Build/Products/Release/Breve.app"
OUT="$ROOT/updates/Breve.zip"
mkdir -p "$ROOT/updates"
rm -f "$OUT"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT"
echo "zip: $OUT"
ls -lh "$OUT"
echo "Proximo passo (local, Keychain --account breve): generate_appcast updates/"
echo "Nao rode generate_appcast sem o zip final que voce pretende hospedar."
