# Fontes do catálogo

O catálogo em `content/development.pt.yaml` e `content/development.en.yaml` é uma introdução. Os exemplos dos cartões são didáticos: não descrevem um sistema em produção nem substituem a documentação original.

As referências ficam fora do balão para preservar a leitura rápida. Cada grupo liga os IDs (iguais nos dois idiomas) às fontes primárias consultadas.

## SOLID, DDD, controllers e CQRS

| IDs | Fontes |
|---|---|
| `god-class`, `srp-reason` | [Robert C. Martin: Single Responsibility Principle](https://blog.cleancoder.com/uncle-bob/2014/05/08/SingleReponsibilityPrinciple.html) |
| `ocp-if`, `ocp-apply` | [Robert C. Martin: Open Closed Principle](https://blog.cleancoder.com/uncle-bob/2014/05/12/TheOpenClosedPrinciple.html), [Princípios e padrões, seção OCP](https://objectmentor.com/resources/articles/Principles_and_Patterns.pdf) |
| `lsp-sub` | [Liskov e Wing: A Behavioral Notion of Subtyping](https://www.cs.cmu.edu/~wing/publications/LiskovWing94.pdf) |
| `isp-fat` | [Robert C. Martin: Interface Segregation Principle](https://objectmentor.com/resources/articles/isp.pdf) |
| `dip` | [Robert C. Martin: Dependency Inversion Principle](https://objectmentor.com/resources/articles/dip.pdf) |
| `what-is-ddd` | [Eric Evans: DDD Reference](https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf) |
| `bounded-context` | [Eric Evans: DDD Reference, Bounded Context](https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf), [Martin Fowler: Bounded Context](https://martinfowler.com/bliki/BoundedContext.html) |
| `aggregate` | [Eric Evans: DDD Reference, Aggregates](https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf), [Martin Fowler: DDD Aggregate](https://martinfowler.com/bliki/DDD_Aggregate.html) |
| `entity-vs-vo` | [Eric Evans: DDD Reference, Entities e Value Objects](https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf), [Microsoft: implementação de objetos de valor](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/implement-value-objects) |
| `fat-controller`, `controller-role` | [Robert C. Martin: Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), [Microsoft: testes unitários de controllers](https://learn.microsoft.com/en-us/aspnet/core/mvc/controllers/testing?view=aspnetcore-10.0) |
| `cqrs-what`, `cqrs-when` | [Microsoft: CQRS pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs), [Martin Fowler: CQRS](https://martinfowler.com/bliki/CQRS.html) |

Cobertura: SOLID (`god-class`, `srp-reason`, `ocp-if`, `ocp-apply`, `lsp-sub`, `isp-fat`, `dip`); DDD (`what-is-ddd`, `bounded-context`, `aggregate`, `entity-vs-vo`); arquitetura (`fat-controller`, `controller-role`, `cqrs-what`, `cqrs-when`).

## Padrões, injeção de dependência, mensageria e idempotência

| IDs | Fontes |
|---|---|
| `strategy-pay`, `strategy-vs-factory` | [OpenTURNS: design patterns](https://openturns.github.io/openturns/latest/developer_guide/architecture.html#design-patterns), [Oracle: Factory Method e Abstract Factory na criação de DAOs](https://www.oracle.com/java/technologies/dataaccessobject.html) |
| `di-lifetimes` | [Microsoft: service lifetimes](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/service-lifetimes) |
| `singleton-dbcontext` | [Microsoft: scope validation](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview#scope-validation), [EF Core: lifetime e segurança de DbContext](https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/) |
| `fix-lifetime` | [Microsoft: scope scenarios](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview#scope-scenarios), [EF Core: DbContext factory](https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/#use-a-dbcontext-factory) |
| `sns-vs-sqs` | [AWS: SNS retries](https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html), [AWS: SNS FIFO archive](https://docs.aws.amazon.com/sns/latest/dg/message-archiving-and-replay-topic-owner.html), [AWS: SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) |
| `pedido-fanout`, `unavailable-consumer` | [AWS: SNS para várias SQS](https://docs.aws.amazon.com/sns/latest/dg/sns-sqs-as-subscriber.html), [Microsoft: competing consumers](https://learn.microsoft.com/en-us/azure/architecture/patterns/competing-consumers) |
| `idempotency` | [AWS: SQS Standard at-least-once](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/standard-queues-at-least-once-delivery.html), [Stripe: idempotência e falhas de rede](https://stripe.com/blog/idempotency) |
| `duplicate-charge` | [Stripe: contrato de idempotency keys](https://docs.stripe.com/api/idempotent_requests), [Stripe: falhas e idempotência](https://stripe.com/blog/idempotency) |
| `dlq` | [AWS: SQS dead-letter queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) |

## Escala, segurança e React

| IDs | Fontes |
|---|---|
| `hpa` | [Kubernetes: HPA](https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/) |
| `pending-pods` | [Kubernetes: recursos dos pods](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| `cloudformation` | [AWS: CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html), [AWS: drift](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html) |
| `bottleneck` | [AWS: testes de carga](https://docs.aws.amazon.com/wellarchitected/latest/framework/perf_process_culture_load_test.html) |
| `jwt-localstorage` | [OWASP: HTML5 Security](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html), [OWASP: Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) |
| `jwt-cookie` | [OWASP: CSRF Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html), [OWASP: Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) |
| `iam-role` | [AWS: credenciais temporárias](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec_identities_unique.html), [AWS: IAM best practices](https://aws.amazon.com/iam/resources/best-practices/), [AWS: Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) |
| `rerender` | [React: Profiler](https://react.dev/reference/react/Profiler), [React: render and commit](https://react.dev/learn/render-and-commit), [React: preservar e reiniciar estado](https://react.dev/learn/preserving-and-resetting-state) |
| `memo-list` | [React: memo](https://react.dev/reference/react/memo), [React: listas](https://react.dev/learn/rendering-lists), [Redux: performance](https://redux.js.org/faq/performance/) |
| `state-realtime` | [Redux: normalized state](https://redux.js.org/usage/structuring-reducers/normalizing-state-shape), [React: atualização de objetos](https://react.dev/learn/updating-objects-in-state) |

A documentação atual do React também descreve otimizações automáticas com React Compiler. O cartão `memo-list` explica `memo` quando a medição mostra trabalho evitável.

## PostgreSQL, observabilidade e RAG

| IDs | Fontes |
|---|---|
| `slow-query` | [Using EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html), [comando EXPLAIN](https://www.postgresql.org/docs/current/sql-explain.html) |
| `when-index` | [Índices com várias colunas](https://www.postgresql.org/docs/current/indexes-multicolumn.html), [índices e ordenação](https://www.postgresql.org/docs/current/indexes-ordering.html) |
| `index-hurts` | [Introdução a índices](https://www.postgresql.org/docs/current/indexes-intro.html) |
| `no-error-logs` | [OpenTelemetry: observabilidade](https://opentelemetry.io/docs/concepts/observability-primer/) |
| `trace` | [OpenTelemetry: traces](https://opentelemetry.io/docs/concepts/signals/traces/) |
| `incident-comms` | [Google SRE: Managing Incidents](https://sre.google/sre-book/managing-incidents/) |
| `what-is-rag` | [Microsoft: desenho e avaliação de RAG](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-solution-design-and-evaluation-guide) |
| `why-rag` | [Microsoft: RAG e busca](https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview) |
| `chunking` | [Microsoft: divisão de documentos](https://learn.microsoft.com/en-us/azure/search/vector-search-how-to-chunk-documents) |
| `hallucination` | [Microsoft: avaliação de respostas RAG](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-llm-evaluation-phase) |

As páginas `current` do PostgreSQL acompanham a série 18. Os cartões usam conceitos gerais, sem depender de recursos exclusivos dessa versão.
