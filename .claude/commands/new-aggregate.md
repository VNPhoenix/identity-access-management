# Command: /new-aggregate

Scaffold a complete DDD aggregate slice for: $ARGUMENTS

## Usage

```
/new-aggregate <aggregate name> [<value objects>] [<child entities>]
```

| Argument | Description | Required |
|---|---|---|
| `<aggregate name>` | PascalCase name of the aggregate | Yes |
| `<value objects>` | Key value objects and their fields | No |
| `<child entities>` | Any child entities and their structure | No |

**When to use:** Adding only the domain layer for a new concept. Use when you want to build layer-by-layer or when infrastructure already exists. Follow with `/new-repository` and `/new-migration` to complete the slice.

## Examples

```
/new-aggregate Product with name, price, and stock quantity
/new-aggregate Order with line items (productId, quantity, unitPrice) and status
/new-aggregate RefreshToken with userId, token hash, expiry, and revoked flag
```

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-design.md`
- `.claude/rules/domain-model.md`
- `.claude/rules/value-objects.md`
- `.claude/rules/aggregates.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/domain-modeling.md`
- `.claude/skills/maven.md`

## Steps

1. Identify the aggregate name, its key value objects, and child entities from: $ARGUMENTS

2. Generate in this order:

   a. `domain/model/{Aggregate}Id.java`
      - Record wrapping UUID **or** Long — choose based on the aggregate (see `value-objects.md`)
      - UUID: `generate()`, `of(UUID)`, `of(String)` static factories
      - Long: `of(Long)`, `of(String)` only — no `generate()`, DB assigns the value
      - Null check (and positivity check for Long) in compact constructor

   b. `domain/model/{ValueObject}.java` for each value object
      - Record with validation in compact constructor
      - Domain behaviour as methods on the record
      - No Spring annotations

   c. `domain/model/{ChildEntity}.java` for each child entity (if any)
      - Has its own typed ID value object
      - Private constructor, static factory
      - No Spring annotations

   d. `domain/event/{EventName}.java` for each domain event
      - Immutable record, past tense name
      - Carries enough data to act on independently

   e. `domain/model/{Aggregate}.java`
      - Private constructor
      - `create(...)` — generates ID, registers creation event
      - `reconstitute(...)` — rebuilds from persistence, no events
      - Domain methods enforce invariants before changing state
      - `reconstituteLine()` for child entities used by JDBC extractor
      - `domainEvents()` returns unmodifiable list
      - All collection accessors return unmodifiable views

   f. `domain/repository/{Aggregate}Repository.java`
      - Interface only — no implementation
      - `void save({Aggregate} aggregate)`
      - `Optional<{Aggregate}> findById({Aggregate}Id id)`

3. Run `mvn compile` and fix any errors.

## Output
List every file created with its full package path.
