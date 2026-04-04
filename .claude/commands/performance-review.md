# Command: /performance-review

Audit the current file for performance issues.

## Rules to follow
- `.claude/rules/jdbc.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/api-design.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/spring-jdbc.md`
- `.claude/skills/spring-rest.md`

## Steps

1. Read the current file and identify its layer.

2. Check for the following issues:

   **JDBC and SQL**
   - Unbounded queries with no `LIMIT` / `Pageable` — full table scan risk
   - Missing `ORDER BY` on paginated queries (non-deterministic results)
   - N+1 pattern: `findById()` called inside a loop — should be a batch query
   - Missing index on columns used in `WHERE`, `JOIN ON`, or `ORDER BY`
   - `SELECT *` instead of explicit column list — fetches unused data
   - Repeated identical queries within a single use case — cache or batch
   - Child collection deleted and re-inserted on every save when only partial changes occurred
   - Count query missing for paginated responses

   **Application layer**
   - Loading full aggregate when only a subset of fields is needed — suggest a view query
   - `@Transactional` missing `readOnly = true` on query-only use cases
   - Multiple repository calls that could be combined into one SQL query
   - Synchronous work inside a request thread that could be async (`@Async` / events)

   **Interface layer**
   - List endpoints returning all records without pagination
   - Response DTOs carrying large nested structures when a summary would suffice
   - No HTTP caching headers (`Cache-Control`, `ETag`) on stable read endpoints

3. For each issue found:
   - Severity: HIGH / MEDIUM / LOW
   - Location: class and method name
   - Explanation of the problem and its impact
   - Optimised version with corrected code

4. End with the highest-impact change to make first.
