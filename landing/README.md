# Landing do Breve

Site estático em Astro. A página simula uma mesa macOS, com janela de apresentação, mascote interativo e modal de instalação.

```bash
cd landing
npm ci
npm run dev
```

`npm run build` gera `dist/`; `npm run preview` abre a versão compilada.

- Página: `src/pages/index.astro`
- Mesa e interações: `src/components/DesktopLanding.astro`, `src/scripts/desktop/landing.js`
- Hero: `src/components/HeroOptions.astro`
- Instalação: `src/components/InstallContent.astro`, `src/scripts/install.js`, `src/data/install.js`
- Visual: `src/styles/desktop.css` e `src/styles/hero-options.css`
- Conteúdo: `src/data/catalog.js`, a partir dos YAML em `content/`

O Dockerfile na pasta `landing/` usa a raiz do repositório como contexto. Explorações e relatórios locais ficam em `reports/`, fora do Git e das rotas do site.
