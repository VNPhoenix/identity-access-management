# Rules

These files define how Claude must behave when reading, generating, or modifying
code in this project. Every rule applies to every task unless a command explicitly
limits scope.

Claude reads all relevant rule files before acting. Commands reference the specific
rules they depend on.

---

## Index

| File | Covers | Applies to |
|---|---|---|
| `code-style.md` | Java 21 features, naming, immutability, size limits | All layers |
| `ddd-layering.md` | Layer responsibilities, dependency direction, package structure | All layers |
| `domain-model.md` | Entities, domain methods, domain events, no-Spring rule | `domain/` |
| `value-objects.md` | Records as value objects, validation, ID types | `domain/` |
| `aggregates.md` | Aggregate roots, boundaries, factories, repository contract | `domain/` |
| `application-layer.md` | Use cases, commands, queries, transaction ownership | `application/` |
| `infrastructure-layer.md` | JDBC repositories, config, migrations, no-business-logic rule | `infrastructure/` |
| `jdbc.md` | NamedParameterJdbcTemplate, SQL style, upsert, type conventions | `infrastructure/` |
| `api-design.md` | Versioning, HTTP verbs, status codes, request/response DTOs | `interface/` |
| `exception-handling.md` | Exception hierarchy, global handler, error response shape | All layers |
| `security.md` | JWT, authorisation, secrets, input validation, sensitive data rules | `interface/`, `infrastructure/` |
| `testing.md` | Test types per layer, JUnit 5, Mockito, Testcontainers conventions | `src/test/` |
| `never-do.md` | Hard stop list — things Claude must never generate | All layers |

---

## Dependency direction

```
interface/   →   application/   →   domain/
                                       ↑
infrastructure/  ─────────────────────┘
```

- `domain/` has zero Spring imports
- `application/` may use `@Service`, `@Transactional`, `ApplicationEventPublisher`
- `infrastructure/` implements domain interfaces using Spring JDBC
- `interface/` uses Spring MVC and Spring Security annotations
