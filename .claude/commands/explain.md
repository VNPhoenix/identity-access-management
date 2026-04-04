# Command: /explain

Explain the current file to a developer unfamiliar with this codebase.

## Rules to follow
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-model.md`
- `.claude/rules/aggregates.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/infrastructure-layer.md`

## Skills to use
- `.claude/skills/domain-modeling.md`

## Steps

1. Read the current file and identify its layer from the package path.

2. Explain based on the layer:

   **domain/model/ — aggregate or entity**
   - What real-world concept this models
   - What invariants it enforces and where
   - What each domain method does and what state it changes
   - What domain events it registers and when
   - Difference between `create()` and `reconstitute()` factories
   - What value objects it uses and why

   **domain/model/ — value object**
   - What concept it represents and why it is a value object (not an entity)
   - What validation it enforces in the compact constructor
   - What domain behaviour its methods provide

   **application/usecase/ — use case**
   - What business operation it fulfils (one sentence)
   - What it loads, what domain method it calls, what it saves
   - What events it publishes
   - What it returns and why

   **infrastructure/persistence/ — JDBC repository**
   - Which domain repository interface it implements
   - How `save()` works — upsert strategy, child collection handling
   - How `findById()` works — join strategy, ResultSetExtractor usage
   - How it maps database rows back to the aggregate via `reconstitute()`

   **interface/controller/ — REST controller**
   - What resource it exposes and at what path
   - Each endpoint: HTTP verb, path, request shape, response shape, status codes
   - Which use case each endpoint delegates to
   - How errors are handled (via global handler)

3. Highlight any non-obvious decisions or gotchas a new developer should know.

4. Keep the explanation concrete and code-referenced — quote specific method names.
