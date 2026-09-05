---
title: Overlay NSPanel + MenuBarExtra
tags: [adr]
updated: 2026-09-04
---

# 4. Overlay `NSPanel` + `MenuBarExtra`

- **Status:** Aceito
- **Data:** 2026-09-04

## Contexto

O pet precisa ficar acima do desktop, sem ícone no Dock, com item na barra. `NSStatusItem` com PNG sem tamanho gerou janela enorme. `@main` só com AppDelegate fez o pet desaparecer.

## Decisão

Manter `SwiftUI.App` + `MenuBarExtra` (ícone 18×18) e overlay `NSPanel` borderless, `.nonactivatingPanel`, `isFloatingPanel = false`, nível `popUpMenu`. Não ativar o app no clique. Cursor de mão via tracking AppKit, não só SwiftUI `onHover`.

## Consequências

O app não rouba foco. Hover e cursor exigem `NSTrackingArea` / monitor. Mudar o `@main` ou tornar o panel floating+activating some o pet.
