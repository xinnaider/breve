# Feed Sparkle

`appcast.xml` é o canal de `SUFeedURL`. O pacote fica no GitHub Release; este arquivo só descreve a versão e a assinatura EdDSA.

Para publicar outra versão:

1. Suba o `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` no `macos/project.yml`.
2. `scripts/package-macos.sh` gera o zip de Release.
3. `generate_appcast --account breve --download-url-prefix https://github.com/xinnaider/breve/releases/download/vX.Y.Z/ /caminho/do/dir-com-o-zip`
4. Copie o `appcast.xml` gerado para `updates/`, ajuste o cask (`version` e `sha256`) e crie o GitHub Release com o mesmo zip.

A chave privada fica no Keychain (`--account breve`). Não a grave neste repositório. A pública é `SUPublicEDKey` no `Info.plist`.
