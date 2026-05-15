# Identity Access Management

This project is a simple implementation of an Identity Access Management (IAM) system. It allows you to manage users, roles, and permissions in a hierarchical structure.

## Prerequisites
- Spring Boot 3.5.13
- Java 21
- Maven 3.9+
- Docker

## Quick Start
1. Clone the repository:
```bash
git clone git@github.com:VNPhoenix/identity-access-management.git
cd identity-access-management
```

2. Build Docker image:
```bash
docker build -t iam .
```

3. Run container using docker compose:
```bash
docker compose up -d
```

## Running tests
```bash
mvn test
```

## Architecture Decisions

Significant architectural choices are documented as ADRs in [`docs/adr/`](docs/adr/README.md).

| Version | Title | Status |
|---|---|---|
| [1.0](docs/adr/ADR-1.0-dockerize-with-layertools.md) | Dockerizing with Spring Boot Layertools | Accepted |

## Further reading
- DDD layering & dependency rules: `.claude/rules/ddd-layering.md`
- Domain model (entities, events): `.claude/rules/domain-model.md`
- Value objects & ID types: `.claude/rules/value-objects.md`
- Aggregates, factories & repositories: `.claude/rules/aggregates.md`
- Use cases, commands & queries: `.claude/rules/application-layer.md`
- Infrastructure layer rules: `.claude/rules/infrastructure-layer.md`
- JDBC conventions & SQL style: `.claude/rules/jdbc.md`
- API design (versioning, HTTP verbs, DTOs): `.claude/rules/api-design.md`
- Exception hierarchy & error responses: `.claude/rules/exception-handling.md`
- Security (JWT, authorisation, secrets, input validation): `.claude/rules/security.md`
- Java 21 style, naming & size limits: `.claude/rules/code-style.md`
- Test conventions (JUnit 5, Mockito, Testcontainers): `.claude/rules/testing.md`
- Hard stop list — never generate: `.claude/rules/never-do.md`
