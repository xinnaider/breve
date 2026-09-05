# Breve

<img src="assets/bonequinho.png" alt="Mascote do Breve" width="96" height="99">

Widget de estudo para macOS 14 ou mais recente: um mascote na borda da tela e notas curtas, em questionário ou texto, a partir de um catálogo YAML.

O aplicativo visível é `Breve.app`. O scheme do Xcode continua `Petzinho` e o identificador do bundle é `dev.fordevs.petzinho`, para preservar as preferências já salvas nesta máquina.

- Site: [breve.jfernando.dev](https://breve.jfernando.dev)
- Código: [github.com/xinnaider/breve](https://github.com/xinnaider/breve)

## O que ele faz

- Mascote na borda, arrastável, sem ícone no Dock
- Catálogo em português e inglês (46 cartões em cada idioma)
- Questionários com três alternativas e notas só informativas
- Recorte de temas e formato na primeira abertura; depois, em Configuração
- Procurar atualização no menu do pet, no menu da barra e em Configuração. Nada é instalado sem a sua confirmação

## Requisitos

- macOS 14 ou mais recente
- Xcode
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Como compilar

```bash
cd macos
xcodegen generate
xcodebuild -scheme Petzinho -configuration Debug -derivedDataPath ./DerivedData -destination 'platform=macOS' build
killall Breve
open DerivedData/Build/Products/Debug/Breve.app
```

Abra o `.app` com `open`. Não lance o binário direto de um shell curto: o processo morre e o pet some. Detalhes em [docs/how-to/compilar-e-abrir.md](docs/how-to/compilar-e-abrir.md).

## Conteúdo

Edite os YAML em `content/`. O contrato dos cartões está em [`content/MODELO.md`](content/MODELO.md). As fontes pedagógicas consultadas para o catálogo estão em [`content/SOURCES.md`](content/SOURCES.md).

Não edite `macos/Resources/*.yaml`: o pre-build copia a partir de `content/`.

## Atualização e distribuição

| Caminho | Situação |
|---|---|
| Compilar deste repositório | Disponível. |
| Homebrew cask | Indisponível. Não há tap nem artefato de release. |
| GitHub Release (zip ou dmg) | Indisponível. |
| Sparkle (atualizar pelo app) | Código no app; [`updates/appcast.xml`](updates/appcast.xml) sem pacote. Sem enclosure, a busca deve informar que não há versão nova, ou falhar se o feed ainda não estiver publicado. Nada é instalado em silêncio. |
| Notarização / Developer ID | Indisponível. Sem isso, o Gatekeeper pode bloquear um app baixado da internet. |

Quando existir um zip assinado com EdDSA num GitHub Release, o cask pretendido deve usar `auto_updates true`: o Homebrew não substitui o `.app` no `brew upgrade` normal; o Sparkle atualiza em Aplicativos depois da confirmação. `brew upgrade --cask --greedy breve` ainda pode puxar o artefato do cask. Isso não deve ser anunciado como instalação funcional antes do arquivo existir.

Como publicar um pacote no feed: [updates/README.md](updates/README.md) e [docs/how-to/atualizar.md](docs/how-to/atualizar.md).

## Landing

Site estático em Astro, na pasta `landing/`:

```bash
cd landing
npm ci
npm run build
```

Há um [`compose.example.yaml`](compose.example.yaml) genérico se você quiser servir a imagem Docker na sua máquina.
