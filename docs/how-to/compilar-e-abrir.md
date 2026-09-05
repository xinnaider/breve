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
xcodebuild -scheme Breve -configuration Debug -derivedDataPath ./DerivedData -destination 'platform=macOS' build
killall Breve
open DerivedData/Build/Products/Debug/Breve.app
```

`xcodegen generate` copia o catálogo de `content/` para `macos/Resources/` e gera o `.xcodeproj`. Rode de novo se você criou arquivo Swift ou mudou `project.yml`.

Abra sempre o `.app` com `open`. Lançar `Breve.app/Contents/MacOS/Breve` de um shell curto mata o processo e o pet some.

Para forçar um card:

```bash
open --env BREVE_CARD=sns-vs-sqs --env BREVE_KIND=quiz DerivedData/Build/Products/Debug/Breve.app
```

Primeira execução: Formato → Temas → Categorias, com etapas numeradas e avanço sequencial. O formato oferece Questionários, Só informativos ou Os dois. O cabeçalho traz a logo, Breve, a versão e as bandeiras de idioma. Ao lado dos idiomas há um botão só com ícone para procurar atualização: o clique abre o diálogo do Sparkle. Nas configurações, as seções são abas sem numeração: o usuário acessa diretamente qualquer uma e pode salvar ali mesmo. Cancelar aparece apenas em Formato; nas demais, Voltar. A janela ajusta sua altura ao conteúdo e mantém os botões logo abaixo dele; conteúdo maior que a tela permite rolagem. Ao concluir, as escolhas são salvas antes da celebração “Tudo pronto para aprender”; “Vamos lá” fecha a janela e abre o conteúdo. A animação respeita Reduzir Movimento do macOS.

Para verificar o primeiro acesso sem alterar as preferências reais, builds Debug aceitam um domínio isolado de UserDefaults. Use um nome novo para começar do zero; reutilize o mesmo nome para verificar a persistência:

```bash
killall Breve
open --env BREVE_DEFAULTS_SUITE=dev.fordevs.breve.setup-test-01 DerivedData/Build/Products/Debug/Breve.app
```

Ao terminar, encerre o app e abra normalmente, sem essa variável, para voltar às preferências reais. A variável não tem efeito em Release.

Reabrir Breve.app enquanto ele já está rodando traz as configurações para a área de trabalho ativa. O menu também oferece Configuração com atalho ⌘,. O item Próximo conteúdo (Next item) pede outra nota ou pergunta agora.
