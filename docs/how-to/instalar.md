---
title: Instalar
tags: [how-to, homebrew]
updated: 2026-09-06
---

# Instalar

No Mac com macOS 14 ou mais recente, Apple Silicon e [Homebrew](https://brew.sh):

```bash
brew tap xinnaider/breve https://github.com/xinnaider/breve
brew install --cask xinnaider/breve/breve
```

O app fica em Aplicativos. Atualizações pelo próprio Breve só instalam depois da sua confirmação.

Se o Homebrew disser que a versão já está instalada mas o `.app` não está em Aplicativos, o receipt ficou sem o arquivo. `brew install` não restaura nesse caso:

```bash
brew reinstall --cask xinnaider/breve/breve
```

## Primeira abertura

1. No Finder, abra **Aplicativos → Breve**. Não desative Gatekeeper nem remova a quarentena.
2. Se o macOS recusar o app não identificado, em **Ajustes do Sistema → Privacidade e Segurança** clique em **Abrir Mesmo**.
3. Confirme **Abrir** no diálogo seguinte.

O Spotlight e o Launch Services só passam a achar o app depois que ele existe de novo em Aplicativos.
