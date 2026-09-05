---
title: Catálogo YAML em content/, copiado no build
tags: [adr]
updated: 2026-09-04
---

# 3. Catálogo YAML em `content/`, copiado no build

- **Status:** Aceito
- **Data:** 2026-09-04

## Contexto

As dicas precisam ser editáveis sem recompilar a lógica, e o app accessory não deve baixar conteúdo.

## Decisão

`content/catalog.yaml` e `content/<tipo>.yaml` são a fonte. O pre-build copia para `macos/Resources/` e o bundle. Decode com Yams. Formato de card, markdown e mapa: `content/MODELO.md`.

## Consequências

Editar dica = YAML + rebuild. `macos/Resources/*.yaml` não se edita à mão e não se commita. YAML stale no bundle é a causa típica de mapa ou campo “sumido”.
