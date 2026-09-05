---
title: Criar uma dica
tags: [how-to, yaml, catalog]
updated: 2026-09-04
---

# Criar uma dica

O contrato completo está em [`content/MODELO.md`](../../content/MODELO.md). Resumo:

1. Edite `content/development.pt.yaml` e o espelho `content/development.en.yaml` (ou crie `content/<tipo>.yaml` e declare em `content/catalog.yaml`).
2. Card mínimo: `id`, `frente`, `verso`.
3. `verso` e `frente` nomeiam a família e o termo por extenso em inglês e em português. Ver `content/MODELO.md`.
4. `explicacao`: uma ideia por linha, linha em branco entre parágrafos. Markdown curto.
5. `quiz` se for pergunta. `mapa` só se a topologia ensinar (fan-out, cadeia).
6. Rebuild. Confira `Breve.app/Contents/Resources/development.pt.yaml`.

Não edite `macos/Resources/*.yaml`. É cópia do pre-build.
