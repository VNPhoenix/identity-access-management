# Command: /review

Review the current file for DDD correctness and Spring Boot best practices.

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-model.md`
- `.claude/rules/value-objects.md`
- `.claude/rules/aggregates.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/jdbc.md`
- `.claude/rules/api-design.md`
- `.claude/rules/exception-handling.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/domain-modeling.md`
- `.claude/skills/spring-rest.md`
- `.claude/skills/spring-jdbc.md`
- `.claude/skills/git.md`

## Steps

1. Read the current file and identify its layer from the package path.

2. Read the git diff to understand what changed recently and focus the review there.

3. Apply the layer-specific checklist:

   **domain/model/ or domain/event/**
   - No Spring annotations anywhere
   - No setters — state changes via named domain methods only
   - All domain primitives wrapped in value objects — no raw UUID, Long, String, BigDecimal
   - Invariants enforced in constructor and domain methods
   - Collections returned as unmodifiable views
   - `create()` and `reconstitute()` factories present and correct
   - Domain events registered inside domain methods, past-tense names
   - Equality based on identity (ID), not field values

   **application/usecase/**
   - `@Service` and constructor injection
   - `@Transactional` on write methods, `@Transactional(readOnly = true)` on reads
   - No SQL, no JDBC, no HTTP concepts
   - Loads aggregate → calls domain method → saves → publishes events → clears events
   - Returns typed result — never a domain aggregate
   - Throws domain exception when aggregate not found

   **infrastructure/persistence/**
   - `NamedParameterJdbcTemplate` only — no positional `?`
   - All SQL in text blocks with aligned keywords
   - `save()` uses ON CONFLICT upsert
   - `findById()` uses `ResultSetExtractor` for one-to-many joins
   - `reconstitute()` factory used — never setters or public constructors
   - `toParams()` extracts all parameter mapping
   - Enums stored via `.name()`, UUIDs and Longs via `.value()`, Instants as TIMESTAMPTZ

   **interface/controller/**
   - Constructor injection only
   - Returns `ResponseEntity` on all methods
   - `@Valid` on all `@RequestBody` parameters
   - No domain objects in request or response — DTOs only
   - No business logic — calls use case only
   - Correct HTTP status codes (201 + Location on POST, 204 on DELETE)
   - No exception handling — delegates to global handler

4. For each issue found:
   - Quote the problematic code
   - State which rule it violates (reference the rule file)
   - Show the corrected version

5. End with a summary: total issues by severity (HIGH / MEDIUM / LOW).
