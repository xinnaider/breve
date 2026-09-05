---
title: Arquitetura
tags: [architecture, overview]
updated: 2026-09-04
---

# Arquitetura do Breve

## Visão geral

Um processo macOS accessory. Sem Dock. Item na barra, pet numa `NSPanel` na borda, setup numa `NSWindow` flutuante. As dicas vêm de YAML no bundle, copiado de `content/` no pre-build. O recorte do usuário fica em UserDefaults.

```
content/*.yaml  --pre-build-->  bundle Resources
                                      |
UserDefaults (recorte, dock, modo)    |
                                      v
Session  -->  WidgetPanelController (NSPanel)
         -->  SetupWindowController (NSWindow)
         -->  MenuBarExtra
         -->  AppUpdater (Sparkle)
```

## Componentes

| Componente | Responsabilidade | Localização |
|---|---|---|
| Catálogo YAML | Tipos, tópicos, cards | `content/` |
| CatalogLoader | Decode Yams → `Catalog` | `macos/Sources/CatalogLoader.swift` |
| Session | Recorte, timers, quiz/info, persistência | `macos/Sources/Session.swift` |
| Overlay | Pet + balão, dock, cursor, drag | `macos/Sources/Widget/` |
| Setup | Bootstrap e configuração | `macos/Sources/Setup/` |
| Menu de barra | Próximo conteúdo, Configuração, atualização, Encerrar | `macos/Sources/BreveApp.swift` |
| Atualizador | Feed Sparkle, diálogo de confirmação | `macos/Sources/AppUpdater.swift` |

## Fluxos principais

1. Launch: `applicationDidFinishLaunching` liga o panel, carrega YAML, aplica UserDefaults. Sem recorte: setup. Com recorte: pet visível, próxima dica em ~30 min ± 20%.
2. Dica: `pickNext` no pool (tipo ligado ∩ tópico marcado). Questionário abre pergunta e alternativas; o mais (explicação) só depois da resposta. Informação abre o verso; o mais mostra extras. Balão some em 10s; hover no pet ou no balão pausa o relógio. Pet fica.
3. Próximo conteúdo (barra ou botão direito): `forceTip()`, outro card agora.
4. Conteúdo novo: editar `content/`, rebuild, conferir o YAML dentro do `.app`.
5. Atualização: ícone no cabeçalho das configurações, menu do pet ou menu da barra. O clique abre o Sparkle. Sem pacote no feed, o ciclo termina sem instalar. Com pacote, o Sparkle pede confirmação antes de substituir o bundle.

## Limites e integrações

- SO: macOS 14+. Accessory via `NSApp.setActivationPolicy(.accessory)`.
- Persistência: `UserDefaults` chave `breve.config.v1`.
- Dependências: Yams ≥ 6.2.2 (YAML) e Sparkle ≥ 2.9.6 (atualização com confirmação).
- Sparkle: feed em `updates/appcast.xml`. Sem iCloud, sem extensão de sistema.

## Restrições e trade-offs

- Overlay não-ativador: não rouba o app da frente. Clique e cursor de mão só no pet e nos controles; o fundo transparente deixa passar.
- `MenuBarExtra` + ícone 18×18: PNG sem tamanho vira janela gigante na barra.
- O comportamento vigente é o código nativo e `content/MODELO.md`.
