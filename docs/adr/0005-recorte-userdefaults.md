---
title: Recorte local em UserDefaults
tags: [adr]
updated: 2026-09-04
---

# 5. Recorte local em UserDefaults

- **Status:** Aceito
- **Data:** 2026-09-04

## Contexto

O usuário escolhe tipos, tópicos e se aprende por questionário, só informação, ou os dois. Não há conta nem sync nesta versão.

## Decisão

Persistir em UserDefaults na chave `petzinho.config.v1`: `bootstrapped`, seleção, dock, `learnQuiz`, `learnInfo`. Sem iCloud. Setup na primeira vez; depois, a mesma janela como Configuração.

## Consequências

Recorte morre com o usuário da máquina. Reset = apagar a chave ou reinstall. Vale na próxima dica e em Trocar.
