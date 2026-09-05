---
title: Atualizar o Breve
tags: [how-to, sparkle, homebrew]
updated: 2026-09-04
---

# Atualizar o Breve

O app usa [Sparkle 2.9](https://sparkle-project.org/documentation/) para procurar e instalar atualizações. `SUAutomaticallyUpdate` e `SUAllowsAutomaticUpdates` ficam desligados: o Sparkle pode checar sozinho, mas só instala depois do diálogo de confirmação.

## No app

1. Ícone ao lado dos idiomas no cabeçalho, botão direito no pet, ou menu da barra.
2. O clique abre o diálogo do Sparkle. Sem pacote no feed: estado "sem atualização" (canal vazio) ou erro (feed inacessível).
3. Se houver versão nova, confirme no Sparkle antes de substituir o bundle e reabrir.

Preferências do usuário (`breve.config.v1`) ficam fora do `.app` e sobrevivem a essa troca.

## Homebrew

O cask `xinnaider/breve/breve` tem `auto_updates true`:

- `brew install --cask` coloca o `.app` em Aplicativos.
- O Sparkle atualiza esse mesmo bundle, com confirmação.
- `brew upgrade` normal não substitui um cask com `auto_updates true`.
- `brew upgrade --cask --greedy breve` pode sobrescrever com o artefato do cask.

## Publicar um pacote

Chave EdDSA: `generate_keys --account breve` (privada no Keychain; pública em `Info.plist` como `SUPublicEDKey`). Não commite a privada.

Passos: [updates/README.md](../../updates/README.md).
