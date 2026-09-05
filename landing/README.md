# Landing do Breve

Site estático em Astro, independente do app macOS. Reutiliza o mascote em `../assets/bonequinho.png`.

```bash
cd landing
npm ci
npm run dev
```

Produção: `npm run build`. Saída em `landing/dist/`. Revisão local: `npm run preview`.

- Página: `src/pages/index.astro`
- Demonstração: `src/components/Demo.astro` e `src/scripts/demo.js`
- Visual: `src/styles/global.css`

Fundo creme, títulos em Besley (servida localmente) e acentos laranja. O mockup de macOS é HTML e CSS; clicar no mascote abre e fecha o informativo, também acessível por teclado. A animação respeita a preferência de movimento reduzido.

O papel de parede está em `src/assets/desktop-wallpaper.png`. O Astro entrega versões WebP responsivas.

O repositório público é `https://github.com/xinnaider/breve`. Não há cask Homebrew publicado e não existe GitHub Release com zip ou dmg. O modal de instalação aponta para o comando real de compilação.

Para servir a imagem Docker na sua máquina, veja `compose.example.yaml` na raiz do repositório.
