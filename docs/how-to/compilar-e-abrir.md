---
title: Compilar e abrir
tags: [how-to, macos, build]
updated: 2026-09-04
---

# Compilar e abrir

Requer Xcode, XcodeGen e macOS 14+.

```bash
cd macos
xcodegen generate
xcodebuild -scheme Petzinho -configuration Debug -derivedDataPath ./DerivedData -destination 'platform=macOS' build
killall Breve
open DerivedData/Build/Products/Debug/Breve.app
```

`xcodegen generate` copia o catálogo de `content/` para `macos/Resources/` e gera o `.xcodeproj`. Rode de novo se você criou arquivo Swift ou mudou `project.yml`.

Abra sempre o `.app` com `open`. Lançar `Breve.app/Contents/MacOS/Breve` de um shell curto mata o processo e o pet some.

Para forçar um card:

```bash
open --env PETZINHO_CARD=sns-vs-sqs --env PETZINHO_KIND=quiz DerivedData/Build/Products/Debug/Breve.app
```

Primeira execução: Formato → Temas → Categorias, com etapas numeradas e avanço sequencial. O formato oferece Questionários, Só informativos ou Os dois. O cabeçalho traz a logo, Breve e as bandeiras de idioma. Nas configurações, as seções são abas sem numeração: o usuário acessa diretamente qualquer uma e pode salvar ali mesmo. Cancelar aparece apenas em Formato; nas demais, Voltar. A janela ajusta sua altura ao conteúdo e mantém os botões logo abaixo dele; conteúdo maior que a tela permite rolagem. Ao concluir, as escolhas são salvas antes da celebração “Tudo pronto para aprender”; “Vamos lá” fecha a janela e abre o conteúdo. A animação respeita Reduzir Movimento do macOS.

Para verificar o primeiro acesso sem alterar as preferências reais, builds Debug aceitam um domínio isolado de UserDefaults. Use um nome novo para começar do zero; reutilize o mesmo nome para verificar a persistência:

```bash
killall Breve
open --env PETZINHO_DEFAULTS_SUITE=dev.fordevs.petzinho.setup-test-01 DerivedData/Build/Products/Debug/Breve.app
```

Ao terminar, encerre o app e abra normalmente, sem essa variável, para voltar às preferências reais. A variável não tem efeito em Release.

O produto se chama Breve; o scheme interno continua Petzinho. O bundle ID e a chave de preferências foram mantidos para preservar a configuração existente. Reabrir Breve.app enquanto ele já está rodando traz as configurações para a área de trabalho ativa. O menu também oferece Configuração com atalho ⌘,.
