---
title: Arquitetura
tags: [architecture, overview]
updated: 2026-09-08
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
         -->  AppUpdater (tag GitHub → compile local)
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
| Atualizador | Release estável, confirmação, compile, helper | `macos/Sources/AppUpdater.swift`, `macos/Sources/Update/` |

## Fluxos principais

1. Launch: `applicationDidFinishLaunching` liga o panel, carrega YAML, aplica UserDefaults. Sem recorte: setup. Com recorte: pet visível, próxima dica em ~30 min ± 20%.
2. Dica: `pickNext` no pool (tipo ligado ∩ tópico marcado). Questionário abre pergunta e alternativas; a explicação só depois da resposta (Ver explicação / Ocultar explicação). Informação abre o verso; Ver mais / Ver menos mostra extras. Balão some em 10s; hover no pet ou no balão pausa o relógio. Pet fica.
3. Próximo conteúdo (barra ou botão direito): `forceTip()`, outro card agora.
4. Conteúdo novo: editar `content/`, rebuild, conferir o YAML dentro do `.app`.
5. Atualização: ícone no cabeçalho, menu do pet ou menu da barra. Consulta `releases/latest` (tag estável, não `main`). Popup Atualizar / Depois. Depois de confirmar: código da tag publicada, compile fora da main thread, validar id/versão/assinatura, helper destaca, troca transacional em `/Applications`, `open`. A troca restaura a cópia anterior se a movimentação falhar; não há rollback automático após um crash.

## Limites e integrações

- SO: macOS 14+. Accessory via `NSApp.setActivationPolicy(.accessory)`.
- Persistência: `UserDefaults` chave `breve.config.v1`.
- Dependências: Yams ≥ 6.2.2 (YAML).
- Publicação do app: GitHub Release / tag `vX.Y.Z`. Push em `main` pode implantar a landing sem ser release do app.

## Restrições e trade-offs

- Overlay não-ativador: não rouba o app da frente. Clique e cursor de mão só no pet e nos controles; o fundo transparente deixa passar.
- `MenuBarExtra` + ícone 18×18: PNG sem tamanho vira janela gigante na barra.
- O comportamento vigente é o código nativo e `content/MODELO.md`.
