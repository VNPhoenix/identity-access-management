# Command: /refactor

Refactor the current file toward correct DDD structure: $ARGUMENTS

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-model.md`
- `.claude/rules/value-objects.md`
- `.claude/rules/aggregates.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/jdbc.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/domain-modeling.md`
- `.claude/skills/spring-jdbc.md`
- `.claude/skills/git.md`
- `.claude/skills/maven.md`

## Steps

1. Read the current file and the git history to understand its original intent.

2. Identify the refactoring target from $ARGUMENTS. Common targets:

   **Extract value object**
   - Find raw primitive (String email, BigDecimal amount, UUID id) used as a domain concept
   - Create a record value object with validation in compact constructor
   - Replace all usages in the aggregate and related classes

   **Extract domain method**
   - Find business logic or state mutation done outside the aggregate (in use case or controller)
   - Move into a named domain method on the aggregate
   - Ensure invariant is enforced inside the method

   **Fix layer violation**
   - Find SQL or JDBC in application or domain layer → move to infrastructure
   - Find business logic in controller → move to use case or domain
   - Find repository called from controller → introduce use case
   - Find domain aggregate returned from controller → introduce response DTO

   **Split use case**
   - Find a use case doing too much (multiple aggregate loads, complex orchestration)
   - Split into focused single-responsibility use cases
   - Coordinate via domain events rather than direct calls

   **Fix JDBC repository**
   - Find setters used in ResultSetExtractor → replace with `reconstitute()` factory
   - Find positional `?` params → replace with named parameters
   - Find missing upsert → replace insert/update logic with ON CONFLICT

3. Preserve all existing behaviour — this is structural only.

4. List every file that needs to change before making any edits.

5. Apply changes file by file.

6. Run `mvn compile` then `mvn test` and fix any failures.

## Output
Before/after summary for each change and list of all files modified.
