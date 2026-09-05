---
title: Atualizar o Breve
tags: [how-to, sparkle, homebrew]
updated: 2026-09-04
---

# Atualizar o Breve

O app usa [Sparkle 2.9](https://sparkle-project.org/documentation/) para procurar e instalar atualizações. `SUAutomaticallyUpdate` e `SUAllowsAutomaticUpdates` ficam desligados: o Sparkle pode checar sozinho, mas só instala depois do diálogo de confirmação.

## No app

1. Botão direito no pet, menu da barra, ou Configuração → Atualização.
2. Procurar atualização.
3. Sem pacote no feed: estado "sem atualização" (canal vazio) ou erro (feed inacessível).
4. Se houver versão nova: o painel mostra as versões. Instalar e reabrir abre o diálogo do Sparkle. Confirme lá antes de substituir o bundle e reabrir.

Preferências do usuário (`petzinho.config.v1`) ficam fora do `.app` e sobrevivem a essa troca.

## Homebrew

Não há cask publicado. Quando existir, o cask deve ter `auto_updates true`. Nesse caso:

- Instalar via `brew install --cask` coloca o `.app` em Aplicativos.
- O Sparkle atualiza esse mesmo bundle, com confirmação.
- `brew upgrade` normal não substitui um cask com `auto_updates true`.
- `brew upgrade --cask --greedy breve` pode sobrescrever com o artefato do cask.

Sem Developer ID e notarização, um zip de release ainda não é uma distribuição Gatekeeper.

## Publicar um pacote

Chave EdDSA: `generate_keys --account breve` (privada no Keychain; pública em `Info.plist` como `SUPublicEDKey`). Não commite a privada.

Passos: [updates/README.md](../../updates/README.md).
