---
title: App nativo macOS, mockup só como referência
tags: [adr]
updated: 2026-09-04
---

# 2. App nativo macOS, mockup só como referência

- **Status:** Aceito
- **Data:** 2026-09-04

## Contexto

Havia mockups HTML para travar visual e fluxo. O produto precisa viver na borda da tela, sem Dock, com persistência local.

## Decisão

O app utilizável é nativo em `macos/` (SwiftUI + AppKit, macOS 14+). HTML de exploração não define o comportamento. Não reimplementar o widget como página no browser.

## Consequências

Uma stack, um processo, overlay real. O código nativo e `content/MODELO.md` mandam no comportamento atual.
