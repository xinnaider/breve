---
title: Por que o overlay é um NSPanel accessory
tags: [explanation, macos]
updated: 2026-09-04
---

# Por que o overlay é um NSPanel accessory

O pet mora na borda enquanto você usa outro app. Se o overlay virar janela normal, o app rouba foco. Se virar `NSStatusItem` sozinho, some da tela. Se o PNG da barra não for redimensionado para 18 pt, a barra explode.

Daí: processo accessory (`setActivationPolicy(.accessory)`), `MenuBarExtra` com `NSImage` 18×18, e `NSPanel` não-ativador no nível de menu popup. Cursor de mão só em controle (pet, alternativa, chevron, badge). Fundo do panel e o cromo vazio do balão não capturam clique. Tracking é AppKit, não SwiftUI `onHover`.

O mockup HTML não reproduz isso. Servir uma página estática não testa o overlay.
