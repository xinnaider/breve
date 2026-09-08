# Instalar o Breve

Requisitos: Apple Silicon, macOS 14+, Xcode e XcodeGen (`brew install xcodegen`). O instalador precisa de permissão de escrita em `/Applications` e não executa sudo.

```bash
curl -fsSL https://raw.githubusercontent.com/xinnaider/breve/main/install.sh | bash
```

[Leia o script antes de executar](../../install.sh). O script em `main` busca a release estável publicada, baixa o código dessa tag e compila o app neste Mac. O código do app instalado não acompanha cada commit de `main`.

O app é instalado em `/Applications/Breve.app`. O cache de compilação fica em `~/Library/Caches/dev.fordevs.breve/src.noindex`. A instalação preserva as preferências e prepara a cópia nova antes de substituir a anterior.

Para compilar um checkout local:

```bash
git clone https://github.com/xinnaider/breve.git
cd breve
./install.sh --local
```

Para apenas compilar, use `./build.sh` e abra com `open app/Breve.app`.

O cask e o ZIP da versão 1.0.2 usam o atualizador antigo. Reinstale pelo comando acima para migrar para o atualizador por compilação local. Não é necessário apagar suas preferências.
