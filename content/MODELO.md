# Como criar uma dica

Fonte: `content/development.pt.yaml` e `content/development.en.yaml`. O build copia para o app. O idioma da UI escolhe qual arquivo carrega. Fontes pedagógicas dos cartões: `content/SOURCES.md`.

Qualquer pessoa escreve YAML. O app cuida de markdown, quiz, mapa e código.

## Checklist de um card

```yaml
      - id: nome-estavel
        frente: "A pergunta, com a família e o termo por extenso."
        verso: "A resposta nomeia o conceito em inglês e em português, depois a regra."
        explicacao: |
          Primeiro parágrafo.

          Segundo parágrafo.

          - item
          - item
        quiz:
          opcoes:
            - "Certa, parafraseando o verso."
            - "Confusão real."
            - "Outra confusão real."
          certa: 0
        mapa:
          layout: fanout
          ...
        codigo: |
          // só se o exemplo ensinar
        depois: "Uma frase depois do código."
```

Obrigatórios: `id`, `frente`, `verso`.
O resto é opcional.

`nota` ainda vale. Se existir `explicacao` e `nota`, vale `explicacao`.

## O que aparece na tela

| Campo | Questionário | Só informação |
|---|---|---|
| `frente` | Pergunta, já visível | Não entra |
| `quiz` | Alternativas, já visíveis | Não entra |
| `verso` | Primeira linha da Explicação, depois de responder | Compacto |
| `explicacao` | Abaixo da Explicação, no mais, só depois de responder | Expandido |
| `mapa` | Abaixo, só se você colocou | Idem |
| `codigo` | Bloco Exemplo | Idem |
| `depois` | Fecho depois do código | Idem |

## Markdown

Vale na `frente`, no `verso`, na `explicacao` e no `depois`. Nas `opcoes` do quiz, texto puro.

```markdown
**negrito** no termo
*itálico* no detalhe
`codigo` em tipo, método, serviço
```

Lista:

```yaml
explicacao: |
  Antes da lista.

  - primeiro item
  - segundo item
```

Parágrafo: uma ideia por linha. Linha em branco entre ideias. O app abre espaço entre cada parágrafo. Sem isso o texto cola.

Não use `#` título. O bloco já se chama Explicação.
Sem travessão.

## Nomear o conceito

O compacto do Informativo é o `verso`. Quem lê não pode depender do chip do tópico.

1. Família na primeira frase: **SOLID**, **DDD**, **CQRS**.
2. Se for letra de acrônimo, a letra: **S de SOLID**.
3. Por extenso em inglês (como a gente fala) e em português: Single Responsibility Principle, Princípio da Responsabilidade Única.
4. Só então a regra.

Na `frente` do quiz, a mesma âncora. "O que o S de SOLID pede", não só "O que o SRP pede".

Nas opções, texto puro. A certa parafraseia o verso. Distrator de sigla também leva o nome por extenso.

## Mapa conceitual

Só quando o desenho mostra uma topologia que o texto não substitui: um evento virando várias filas, uma cadeia. Lembrete de duas frases (SNS avisa, SQS enfileira) não leva mapa.

`kind`: `sns`, `sqs`, `event`, `service`. Aceita `topic`/`topico`, `queue`/`fila`.

### fanout (um vira vários)

```yaml
mapa:
  layout: fanout
  titulo: Fan-out
  origem:
    label: Pedido aprovado
    kind: event
  hub:
    label: PedidoAprovado
    kind: sns
  destinos:
    - label: estoque
      kind: sqs
    - label: antifraude
      kind: sqs
```

### chain (sequência)

```yaml
mapa:
  layout: chain
  origem:
    label: Checkout
    kind: event
  destinos:
    - label: fila do estoque
      kind: sqs
```

### compare (lado a lado)

Só se os dois lados tiverem estrutura, não um slogan.

```yaml
mapa:
  layout: compare
  destinos:
    - label: "Scoped por request"
      kind: service
    - label: "Singleton vive o processo"
      kind: service
```

Label curto. No compare, os dois no mesmo formato.

## Exemplo para copiar

```yaml
      - id: sns-vs-sqs
        frente: "Qual a forma mais simples de lembrar SNS vs SQS?"
        verso: "**SNS** (Simple Notification Service) avisa. **SQS** (Simple Queue Service) enfileira."
        explicacao: |
          **N** de *notify*, **Q** de *queue*.

          **SNS** é o megafone: você publica no tópico e quem assinou recebe. A mensagem não fica esperando alguém buscar.

          **SQS** é a fila: a mensagem para até um consumidor processar. Se o serviço cair, ela continua lá.

          O padrão comum junta os dois. SNS espalha, cada consumidor tem a própria SQS.
        quiz:
          opcoes:
            - "SNS avisa (pub/sub). SQS enfileira."
            - "SNS é a fila. SQS é o tópico."
            - "Os dois guardam a mensagem até o consumidor buscar."
          certa: 0
```

Sem `mapa` neste. Fan-out de pedido aprovado, sim.

## Tipo novo

1. Crie `content/<id>.yaml` com `topics` e `cards`.
2. Em `content/catalog.yaml`, declare o tipo com `source: <id>.yaml` e `available: true`.
3. Rebuild. O pre-build copia o YAML para o bundle.

## Conferir

- Quiz: pergunta e alternativas já visíveis. Depois de responder, mais abre a Explicação.
- Info: compacto é o verso. Expandiu: explicação, e mapa só se o YAML tiver.
- Uma ideia por linha na `explicacao`.
