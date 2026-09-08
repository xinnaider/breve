export const INSTALL_CMD =
  "curl -fsSL https://raw.githubusercontent.com/xinnaider/breve/main/install.sh | bash";
export const SCRIPT_URL =
  "https://raw.githubusercontent.com/xinnaider/breve/main/install.sh";
export const HELP_URL =
  "https://github.com/xinnaider/breve/blob/main/docs/how-to/instalar.md";
export const REPO = "https://github.com/xinnaider/breve";

export const NOTE = {
  topic: "SOLID / OOP",
  kind: "Informativo",
  title: "S de SOLID: responsabilidade única.",
  body: "Separe tarefas que mudam por necessidades diferentes. Uma nova regra de salário não deveria exigir alterar a geração de relatórios.",
  explanation: [
    "O Single Responsibility Principle (SRP) agrupa código que atende à mesma responsabilidade. A expressão “um motivo para mudar” se refere à necessidade que leva alguém a pedir uma alteração.",
    "Por exemplo: o financeiro muda a regra de salário; a auditoria muda o relatório. Separar essas responsabilidades reduz a chance de uma mudança atrapalhar a outra.",
  ],
};

export const QUIZ = {
  topic: "SOLID / OOP",
  kind: "Questão",
  title: "No S de SOLID, por que separar o cálculo de salário da geração de relatórios?",
  options: [
    "Porque regras de salário e formatos de relatório atendem a necessidades diferentes.",
    "Porque cada classe deve ter exatamente um método.",
    "Porque duas tarefas nunca podem fazer parte do mesmo fluxo.",
  ],
  correct: 0,
  explanation:
    "O Single Responsibility Principle (SRP) agrupa código que atende à mesma responsabilidade. A expressão “um motivo para mudar” se refere à necessidade que leva alguém a pedir uma alteração.",
};

export const QUIZ_NEXT = {
  topic: "SOLID / OOP",
  kind: "Questão",
  title: "Uma classe calcula descontos, monta relatórios e executa SQL. Por que isso pode dificultar mudanças?",
  options: [
    "Tarefas que evoluem separadamente ficaram concentradas na mesma classe.",
    "Qualquer classe que chama vários serviços é uma God Class.",
    "O problema só existe depois de ultrapassar mil linhas.",
  ],
  correct: 0,
  explanation:
    "God Class é uma classe que concentra tarefas demais. Misturar regras de desconto, relatórios e acesso ao banco torna mudanças independentes mais difíceis de isolar.",
};
