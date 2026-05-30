# Command: /new-repository

Scaffold a Spring Data JDBC repository for: $ARGUMENTS

## Usage

```
/new-repository <aggregate name>
```

| Argument | Description | Required |
|---|---|---|
| `<aggregate name>` | PascalCase name of an existing domain aggregate (e.g. `User`, `Role`). The aggregate and its repository interface must already exist in the project. | Yes |

**When to use:** After `/new-aggregate`, when the JDBC persistence layer does not yet exist. Reads the domain aggregate and repository interface already present in the project and generates the four infrastructure classes (`DbEntity`, `DbRepository`, `DbMapper`, `Jdbc{Aggregate}Repository`).

## Examples

```
/new-repository User
/new-repository Role
/new-repository RefreshToken
```

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/spring-data-jdbc.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/spring-data-jdbc.md`
- `.claude/skills/maven.md`

## Steps

1. Read the existing domain aggregate and repository interface from the project.

2. Generate `infrastructure/persistence/{Aggregate}DbEntity.java`:
   - `@Table("table_name")` on the class
   - `@Id` on a raw UUID or Long field (no value object wrapper)
   - `@MappedCollection(idColumn = "fk_col")` on child entity lists
   - UUID IDs: implements `Persistable<UUID>` with `@Transient boolean isNew`
   - Long IDs: `Long id` (null = new entity) — no `Persistable` needed
   - Child DB entity class for each child entity

3. Generate `infrastructure/persistence/{Aggregate}DbRepository.java`:
   - `@Repository`, extends `ListCrudRepository<{Aggregate}DbEntity, UUID>`
   - Add `@Query` methods for pagination and custom filters; named params only

4. Generate `infrastructure/persistence/{Aggregate}DbMapper.java`:
   - `@Component`
   - `toDomain({Aggregate}DbEntity)` → calls `{Aggregate}.reconstitute(...)`, unwraps raw types to value objects
   - `toEntity({Aggregate})` → sets all raw fields, sets `isNew = aggregate.isNew()`

5. Generate `infrastructure/persistence/Jdbc{Aggregate}Repository.java`:
   - `@Repository`, `@RequiredArgsConstructor`, implements `{Aggregate}Repository`
   - `save()` → `dbRepository.save(mapper.toEntity(aggregate))`
   - `findById()` → `dbRepository.findById(id.value()).map(mapper::toDomain)`

6. Add `isNew()` method to the domain aggregate if not present:
   - `private final boolean isNew` field (set to `true` in `create()`, `false` in `reconstitute()`)
   - `public boolean isNew() { return isNew; }` — pure Java, no Spring imports

7. Run `mvn compile` and fix any errors.

## Output
List every file created or modified with its full package path.