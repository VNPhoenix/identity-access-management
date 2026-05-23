# CLAUDE.md — Project Rules

## Stack
- Java 21
- Spring Boot 3.5
- Spring MVC (REST)
- Spring Security 6
- Spring Data JDBC — repository interfaces, entity mapping, custom `@Query` SQL; no ORM
- Maven (single module)
- JUnit 5, Mockito, Testcontainers for testing

## Database
- PostgreSQL 17
- Flyway for schema migrations (SQL-based, no Java migrations)
- Primary keys: UUID (`gen_random_uuid()`) or Long (`BIGINT GENERATED ALWAYS AS IDENTITY`) — chosen per aggregate

## What NOT to use
- No ORM (no Hibernate, no Spring Data JPA, no JPA annotations)

## Architecture
Domain-Driven Design (DDD) with four layers:

```
interface/        ← controllers, request/response DTOs, exception handlers
application/      ← use cases, application services, command/query objects
domain/           ← aggregates, entities, value objects, domain services, repository interfaces, domain events
infrastructure/   ← repository implementations (JDBC), Spring config, Flyway migrations
```

## Rules
All rules live in `.claude/rules/`. Claude must follow every rule file before
generating or modifying any code.

- `code-style.md`           — Java 21 style, naming, immutability
- `ddd-layering.md`         — layer responsibilities and dependency rules
- `domain-model.md`         — aggregates, entities, domain rules
- `value-objects.md`        — how to model value objects
- `aggregates.md`           — aggregate design and boundaries
- `application-layer.md`    — use cases, commands, queries
- `infrastructure-layer.md` — JDBC repositories, config, adapters
- `spring-data-jdbc.md`     — Spring Data JDBC mapping, @Query conventions
- `api-design.md`           — REST conventions, versioning, response shapes
- `exception-handling.md`   — domain exceptions, global handler
- `security.md`             — JWT, authorisation, secrets, input validation rules
- `testing.md`              — JUnit 5, Mockito, Testcontainers conventions
- `never-do.md`             — hard stop list

## Skills
All skills live in `.claude/skills/`. Claude uses these when writing or running code.

- `maven.md`           — compile, test, verify goals and conventions
- `git.md`             — read history/diff, commit message format
- `spring-rest.md`     — how to build REST controllers and filters
- `spring-security.md` — SecurityFilterChain, JWT, method security
- `spring-data-jdbc.md` — Spring Data JDBC repository, entity mapping, @Query
- `domain-modeling.md` — how to model aggregates, VOs, domain events
- `testing.md`         — slice tests, unit tests, Testcontainers setup

## Commands
All commands live in `.claude/commands/`. Each command references the rules
and skills it depends on.

- `new-aggregate.md`      — scaffold aggregate + value objects + repository interface
- `new-use-case.md`       — scaffold application service + command/query
- `new-repository.md`     — scaffold JDBC repository implementation
- `new-migration.md`      — generate Flyway SQL migration
- `add-endpoint.md`       — add REST endpoint wired to a use case
- `new-feature.md`        — scaffold full vertical slice end-to-end
- `write-tests.md`        — generate tests for the current file
- `add-test-case.md`      — add a missing test case
- `review.md`             — review for DDD + Spring best practices
- `security-audit.md`     — audit for security vulnerabilities
- `performance-review.md` — audit for JDBC and API performance issues
- `refactor.md`           — structural refactoring toward DDD
- `debug.md`              — diagnose a described runtime issue
- `explain.md`            — explain the current file to a new developer
