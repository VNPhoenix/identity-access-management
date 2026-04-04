# Command: /add-endpoint

Add a new REST endpoint for: $ARGUMENTS

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/api-design.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/exception-handling.md`
- `.claude/rules/security.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/spring-rest.md`
- `.claude/skills/domain-modeling.md`
- `.claude/skills/maven.md`

## Steps

1. Read the existing controller, use cases, and domain model for this resource.

2. Determine the HTTP verb, path, request body, and response shape from: $ARGUMENTS

3. Create or update `application/command/` or `application/query/`:
   - New command record if this is a write operation
   - New query record and view record if this is a read operation
   - Use domain value object types in command/query fields — not raw UUID or String

4. Create `application/usecase/{Action}{Aggregate}UseCase.java`:
   - `@Service`, constructor injection
   - `@Transactional` for writes, `@Transactional(readOnly = true)` for reads
   - Load → mutate domain → save → publish events
   - Return typed result — never a domain aggregate

5. Add the handler method to the existing controller:
   - Correct HTTP verb and versioned path (`/api/v1/...`)
   - `@Valid` on `@RequestBody` if a request body is accepted
   - Build command/query from request DTO
   - Call use case
   - Map result to response DTO
   - Return `ResponseEntity` with correct status code

6. Add request/response DTO records to `interface/dto/` if new ones are needed.

7. Run `mvn compile` and fix any errors.

## Output
List every file created or modified with its full package path.
