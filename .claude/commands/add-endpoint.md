# Command: /add-endpoint

Add a new REST endpoint for: $ARGUMENTS

## Usage

```
/add-endpoint <HTTP verb> <path> [<request / response shape>] [<authorization>]
```

| Argument | Description | Required |
|---|---|---|
| `<HTTP verb>` | GET, POST, PUT, PATCH, or DELETE | Yes |
| `<path>` | Full versioned path (e.g. `/api/v1/users/{id}`) | Yes |
| `<request / response shape>` | What the request body carries and what the response returns | No |
| `<authorization>` | Access requirement (admin only, owner only, public) | No |

**When to use:** Adding a single new REST endpoint to an existing controller and wiring it to a new use case. Use `/new-feature` instead if the resource (controller, domain aggregate) does not yet exist.

## Examples

```
/add-endpoint POST /api/v1/users to create a user with email and password — returns 201
/add-endpoint GET /api/v1/users/{id} returning user details — 200 or 404
/add-endpoint DELETE /api/v1/roles/{id} admin only — returns 204
/add-endpoint PATCH /api/v1/users/{id}/deactivate — owner or admin
```

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-design.md`
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

6. Add `@PreAuthorize` where required (see `security.md`):
   - Admin-only operations: `@PreAuthorize("hasRole('ADMIN')")`
   - Owner-only operations: verify ownership in the use case, not the controller
   - Public endpoints (auth flows): no `@PreAuthorize` needed — already `permitAll()` in SecurityFilterChain

7. Add request/response DTO records to `interface/dto/` if new ones are needed.

8. Run `mvn compile` and fix any errors.

## Output
List every file created or modified with its full package path.
