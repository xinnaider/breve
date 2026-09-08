# Releases do app vs landing

`updates/appcast.xml` é o feed Sparkle dos clientes **1.0.2**. Builds novos não o lêem.

Release do **app**: crie uma tag `vX.Y.Z` e um GitHub Release **não** draft / **não** prerelease. O `MARKETING_VERSION` em `macos/project.yml` tem de ser exatamente `X.Y.Z`. O atualizador e o `install.sh` usam o `tarball_url` dessa release.

Push em `main` **não** é release do app. Se o deploy da landing estiver ligado a `main`, um push publica o site sem tornar aquele commit a versão instalável.

Antes de publicar, revise o conteúdo público, execute `tests/update/run.sh` e compile com `./build.sh`. A tag deve incluir `build.sh`, o projeto macOS, conteúdo e helpers. Não mova tags já publicadas.

O zip + `generate_appcast` (`scripts/package-macos.sh`) é legado. Não é o canal do app novo.
