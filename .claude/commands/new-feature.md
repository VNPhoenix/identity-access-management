# Command: /new-feature

Scaffold a complete vertical feature slice for: $ARGUMENTS

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-model.md`
- `.claude/rules/value-objects.md`
- `.claude/rules/aggregates.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/spring-data-jdbc.md`
- `.claude/rules/api-design.md`
- `.claude/rules/exception-handling.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/domain-modeling.md`
- `.claude/skills/spring-rest.md`
- `.claude/skills/spring-data-jdbc.md`
- `.claude/skills/maven.md`

## Steps — generate in this order

### 1. Domain layer
Run `/new-aggregate $ARGUMENTS` steps:
- `{Aggregate}Id.java`
- Value object classes
- Child entity classes (if any)
- Domain event records
- `{Aggregate}.java` aggregate root
- `{Aggregate}Repository.java` interface

### 2. Application layer
For the initial CRUD use cases:
- `Create{Aggregate}Command.java`
- `Create{Aggregate}UseCase.java` — `@Transactional`
- `Get{Aggregate}Query.java` + `{Aggregate}View.java`
- `Get{Aggregate}UseCase.java` — `@Transactional(readOnly = true)`
- `List{Aggregate}sQuery.java`
- `List{Aggregate}sUseCase.java` — `@Transactional(readOnly = true)`

### 3. Infrastructure layer
Run `/new-repository $ARGUMENTS` steps:
- `{Aggregate}DbEntity.java` — Spring Data JDBC annotations on DB entity only
- `{Aggregate}DbRepository.java` — extends `ListCrudRepository<{Aggregate}DbEntity, UUID>`
- `{Aggregate}DbMapper.java` — domain ↔ DB entity conversion
- `Jdbc{Aggregate}Repository.java` — implements domain repository interface
- Add `isNew()` pure Java method to the domain aggregate

### 4. Migration
Run `/new-migration` steps:
- `V{next}__{aggregate_table}.sql`
- Table with `id` (`UUID PRIMARY KEY` or `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`), domain columns, `created_at`, `updated_at`

### 5. Interface layer
- `{Aggregate}Controller.java` at `/api/v1/{aggregates}`
  - `POST /` → create (201 + Location)
  - `GET /{id}` → get by id (200 or 404)
  - `GET /` → paginated list (200)
- `Create{Aggregate}Request.java` — request record with Bean Validation
- `{Aggregate}Response.java` — response record
- Add `{Aggregate}NotFoundException` to global handler if not already present

### 6. Verify
- `mvn flyway:migrate`
- `mvn compile`

## Output
Full file tree of everything created, grouped by layer.
