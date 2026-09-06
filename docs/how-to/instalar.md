---
title: Instalar
tags: [how-to, macos, build]
updated: 2026-09-06
---

# Instalar

O Breve é compilado no seu Mac (mesmo modelo do [Interruptor](https://github.com/xinnaider/interruptor)): o `.app` não vem baixado da internet, então o Gatekeeper não mostra *A Apple não pôde verificar…*.

Requisitos: macOS 14+, Apple Silicon, Xcode e XcodeGen (`brew install xcodegen`).

```bash
curl -fsSL https://raw.githubusercontent.com/xinnaider/breve/main/install.sh | bash
```

O script clona para `~/.local/src/breve`, gera o Release e copia para `/Applications/Breve.app`.

Manualmente, a partir do repositório:

```bash
git clone https://github.com/xinnaider/breve.git
cd breve
./build.sh
open app/Breve.app
```

Para atualizar: rode de novo o `install.sh`, ou `git pull` e `./build.sh` na pasta do clone.

Não desative o Gatekeeper nem remova quarentena de outros apps. Um zip ou cask baixado da internet continua sujeito ao diálogo da Apple; o caminho suportado é este build local.
