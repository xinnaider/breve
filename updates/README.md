# Feed Sparkle

`appcast.xml` é o canal apontado por `SUFeedURL` no `Info.plist`. O canal está vazio de propósito: ainda não há zip de release assinado com EdDSA neste repositório.

Ferramentas: baixe a [release 2.9.x do Sparkle](https://github.com/sparkle-project/Sparkle/releases) e use os binários `generate_keys` e `generate_appcast` do diretório `bin/` do pacote (ou coloque-os no `PATH`).

Quando houver um `Breve.app` de Release que você pretende hospedar:

```bash
ditto -c -k --sequesterRsrc --keepParent \
  macos/DerivedData/Build/Products/Release/Breve.app \
  updates/Breve.zip

generate_appcast --account breve updates/
```

O `generate_appcast` preenche `sparkle:edSignature` e o `enclosure`. Sem Developer ID e notarização o arquivo ainda pode ser assinado no Sparkle, mas o Gatekeeper pode bloquear a instalação em outras máquinas.

Não coloque a chave privada neste diretório. A pública fica em `Info.plist` (`SUPublicEDKey`). A privada deve permanecer no Keychain da conta `breve`.
