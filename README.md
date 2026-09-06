# Breve

<img src="assets/bonequinho.png" alt="Mascote do Breve" width="96" height="99">

Seu parceiro de estudo no Mac. Um mascote na borda da tela traz notas curtas e perguntas, no seu ritmo, sem ocupar o dia.

- Aprenda um pouco por vez, no canto da tela
- Escolha os temas e o formato: questionário, texto, ou os dois
- Português e inglês
- Sem ícone no Dock; atualiza pelo próprio app, só depois da sua confirmação

## Instalar

O app é compilado **neste Mac**. Assim o Gatekeeper não trata o Breve como um download da internet.

Requisitos: macOS 14+, Apple Silicon, [Xcode](https://developer.apple.com/xcode/) e [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
curl -fsSL https://raw.githubusercontent.com/xinnaider/breve/main/install.sh | bash
```

Ou manualmente:

```bash
git clone https://github.com/xinnaider/breve.git
cd breve
./build.sh
open app/Breve.app
```

Site: [breve.jfernando.dev](https://breve.jfernando.dev)

Código: [github.com/xinnaider/breve](https://github.com/xinnaider/breve)

Ajuda: [docs/how-to/instalar.md](docs/how-to/instalar.md). Desenvolvimento Debug: [docs/how-to/compilar-e-abrir.md](docs/how-to/compilar-e-abrir.md).
