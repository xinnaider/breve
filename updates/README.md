# Releases do app vs landing


Release do **app**: crie uma tag `vX.Y.Z` e um GitHub Release **não** draft / **não** prerelease. O `MARKETING_VERSION` em `macos/project.yml` tem de ser exatamente `X.Y.Z`. O atualizador e o `install.sh` usam o `tarball_url` dessa release.

Push em `main` **não** é release do app. Se o deploy da landing estiver ligado a `main`, um push publica o site sem tornar aquele commit a versão instalável.

Antes de publicar, revise o conteúdo público, execute `tests/update/run.sh` e compile com `./build.sh`. A tag deve incluir `build.sh`, o projeto macOS, conteúdo e helpers. Não mova tags já publicadas.
