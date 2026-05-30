# Command: /new-use-case

Scaffold a use case (application service) for: $ARGUMENTS

## Usage

```
/new-use-case <business operation> [for <aggregate name>] [read only]
```

| Argument | Description | Required |
|---|---|---|
| `<business operation>` | Plain-English action (e.g. "Place order", "Revoke refresh token") | Yes |
| `<aggregate name>` | The aggregate this use case operates on | No |
| `read only` | Literal text — signals this is a query use case, not a command | No |

**When to use:** Adding a new application service after the domain aggregate already exists. Use for each distinct business operation beyond the CRUD baseline scaffolded by `/new-feature`.

## Examples

```
/new-use-case Place order for the Order aggregate
/new-use-case Get user by ID — read only
/new-use-case Revoke refresh token for the RefreshToken aggregate
/new-use-case List active roles paginated — read only
```

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-design.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/exception-handling.md`
- `.claude/rules/security.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/domain-modeling.md`
- `.claude/skills/maven.md`

## Steps

1. Determine from $ARGUMENTS whether this is a command (write) or query (read) use case.

2. Generate the command or query object:

   Command (write):
   ```
   application/command/{Action}{Aggregate}Command.java
   ```
   - Immutable record
   - Fields use domain value object types — not raw UUID or String

   Query (read):
   ```
   application/query/Get{Aggregate}Query.java
   application/query/{Aggregate}View.java   ← read model record, not the domain aggregate
   ```

3. Generate the use case class:
   ```
   application/usecase/{Action}{Aggregate}UseCase.java
   ```
   - Annotated with `@Service`
   - Constructor injection, all fields `private final`
   - `@Transactional` on execute() for write use cases
   - `@Transactional(readOnly = true)` for read use cases
   - Load aggregate via repository → call domain method → save → publish events
   - Return typed result (ID, view record) — never return domain aggregate directly
   - Throw domain exception if aggregate not found

4. Publish domain events after saving:
   ```java
   order.domainEvents().forEach(eventPublisher::publishEvent);
   order.clearDomainEvents();
   ```

5. Run `mvn compile` and fix any errors.

## Output
List every file created with its full package path.
