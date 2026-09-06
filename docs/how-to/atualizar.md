---
title: Atualizar o Breve
tags: [how-to, sparkle]
updated: 2026-09-06
---

# Atualizar o Breve

Instalação pelo `install.sh` / `./build.sh`: atualize com o **mesmo comando**. O script faz `git pull`, recompila neste Mac e substitui `/Applications/Breve.app`.

```bash
curl -fsSL https://raw.githubusercontent.com/xinnaider/breve/main/install.sh | bash
```

Ou, no clone:

```bash
git pull
./build.sh
open app/Breve.app
```

Preferências (`breve.config.v1`) ficam fora do `.app` e sobrevivem.

## No app

O ícone ao lado dos idiomas ainda pode consultar o feed Sparkle (zip no GitHub). Esse pacote **é** um download e o macOS pode recusar. O caminho suportado sem o diálogo da Apple é recompilar localmente, como acima.

## Publicar um pacote

Chave EdDSA: `generate_keys --account breve` (privada no Keychain; pública em `Info.plist` como `SUPublicEDKey`). Não commite a privada.

Passos: [updates/README.md](../../updates/README.md).
