# Atualizar o Breve

O Breve consulta a release estável publicada no GitHub. Uma tag `vX.Y.Z` só é oferecida quando sua versão é maior que a instalada; drafts e pré-releases não são oferecidos.

Na abertura, uma versão nova exibe **Atualizar** e **Depois**. Também é possível buscar pelo ícone ao lado dos idiomas nas configurações ou pelo menu do mascote.

Após confirmar, o app baixa o código por HTTPS, confere a versão, compila neste Mac e verifica o identificador e a assinatura do bundle. Um helper aguarda o app encerrar, substitui `/Applications/Breve.app` e o reabre. A compilação leva alguns minutos e exige Xcode e XcodeGen.

A cópia anterior é mantida durante a troca e restaurada se a movimentação da nova cópia falhar. Isso não equivale a rollback automático de crashes depois da abertura. Preferências ficam fora do `.app` e são preservadas.

Para reinstalar ou migrar do ZIP/Sparkle 1.0.2:

```bash
curl -fsSL https://raw.githubusercontent.com/xinnaider/breve/main/install.sh | bash
```

O script em `main` instala a release publicada. Para instalar o código de um checkout revisado, use `./install.sh --local`.

O feed `updates/appcast.xml` é legado: builds novos não usam Sparkle. Veja [como publicar uma release](../../updates/README.md).
