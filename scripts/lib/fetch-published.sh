#!/bin/bash
# Lê a release estável no GitHub (não main). Escreve TAG, TARBALL, VERSION, COMMITISH.
set -euo pipefail

API="${BREVE_RELEASE_API:-https://api.github.com/repos/xinnaider/breve/releases/latest}"
JSON="${BREVE_RELEASE_JSON:-}"

if [[ -z "$JSON" ]]; then
  JSON="$(/usr/bin/curl -fsSL -A "Breve-installer (dev.fordevs.breve)" "$API")"
fi

python3 - "$JSON" <<'PY'
import json, os, re, sys, shlex
raw = sys.argv[1]
data = json.loads(raw)
if data.get("draft") or data.get("prerelease"):
    sys.exit("release não é estável")
tag = data.get("tag_name") or ""
if not re.fullmatch(r"v?[0-9]+\.[0-9]+\.[0-9]+", tag):
    sys.exit("tag inválida")
tarball = data.get("tarball_url") or ""
from urllib.parse import urlparse
host = urlparse(tarball).hostname or ""
if urlparse(tarball).scheme != "https" or host not in {"api.github.com", "codeload.github.com", "github.com"}:
    sys.exit("origem do tarball recusada")
if "xinnaider/breve" not in tarball:
    sys.exit("repositório inesperado")
version = tag[1:] if tag.startswith("v") else tag
print(f"TAG={tag}")
print(f"VERSION={version}")
print("TARBALL=" + shlex.quote(tarball))
print("COMMITISH=" + shlex.quote(str(data.get("target_commitish") or "")))
print("RELEASE_ID=" + shlex.quote(str(data.get("id") or "")))
PY
