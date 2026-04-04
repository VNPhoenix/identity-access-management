# Command: /new-repository

Scaffold a JDBC repository implementation for: $ARGUMENTS

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/jdbc.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/spring-jdbc.md`
- `.claude/skills/maven.md`

## Steps

1. Read the existing domain repository interface and aggregate from the project.

2. Generate `infrastructure/persistence/Jdbc{Aggregate}Repository.java`:
   - Implements the domain repository interface
   - Annotated with `@Repository`
   - Constructor injection of `NamedParameterJdbcTemplate`
   - `save()` uses ON CONFLICT upsert
   - `findById()` uses LEFT JOIN for child collections
   - Private `toParams(Aggregate)` method returns `MapSqlParameterSource`
   - Child collection save handled in a private `save{Children}()` method:
     - Delete existing children then re-insert (simplest correct approach)

3. Generate `infrastructure/persistence/{Aggregate}ResultSetExtractor.java`:
   - Implements `ResultSetExtractor<List<{Aggregate}>>`
   - Annotated with `@Component`
   - Uses `LinkedHashMap` to group child rows by aggregate ID
   - Calls `{Aggregate}.reconstitute(...)` — never setters or public constructor
   - Calls `aggregate.reconstituteLine(...)` for child entities

4. Use text blocks for all SQL. Named parameters only. Follow type conventions:
   - UUID → `.value()`
   - Long → `.value()`
   - Enum → `.name()`
   - Instant → stored as TIMESTAMPTZ

5. Run `mvn compile` and fix any errors.

## Output
List every file created with its full package path.
