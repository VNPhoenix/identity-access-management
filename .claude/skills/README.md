# Skills

These files teach Claude how to write code for the specific tools and patterns
used in this project. Commands reference the skills they need.

---

## Index

| File | Covers | Used by commands |
|---|---|---|
| `maven.md` | Compile, test, verify goals, pom.xml conventions | All commands |
| `git.md` | Read history/diff, commit message format, branch naming | `review`, `debug`, `refactor` |
| `spring-rest.md` | Controller pattern, request/response DTOs, mapper pattern | `add-endpoint`, `new-feature`, `review` |
| `spring-security.md` | SecurityFilterChain, JWT filter, `@PreAuthorize`, method security | `security-audit`, `add-endpoint` |
| `spring-jdbc.md` | NamedParameterJdbcTemplate, upsert, ResultSetExtractor, pagination | `new-repository`, `new-feature`, `performance-review` |
| `domain-modeling.md` | Aggregate template, value object template, factory methods, domain events | `new-aggregate`, `new-use-case`, `new-feature`, `refactor` |
| `testing.md` | Unit, slice, and integration test patterns per layer | `write-tests`, `add-test-case`, `debug` |

---

## How skills relate to rules

Skills are the *how* — concrete patterns and code templates.
Rules are the *what* — constraints and standards to enforce.

A skill shows you how to write a JDBC repository.
The rule (`jdbc.md`) tells you what you must never do in that repository.

Always satisfy the rule. Use the skill as the implementation guide.
