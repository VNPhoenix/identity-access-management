# Command: /debug

Diagnose and fix the following issue in the current file: $ARGUMENTS

## Rules to follow
- `.claude/rules/ddd-layering.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/jdbc.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/maven.md`
- `.claude/skills/git.md`

## Steps

1. Read the current file carefully.

2. Read `git diff` and `git log --oneline -10` to understand what changed recently.

3. Check the most common Spring + DDD pitfalls matching the symptom in $ARGUMENTS:

   **Transaction issues**
   - `@Transactional` method called from within the same class (self-invocation — proxy bypassed)
   - Checked exception thrown inside `@Transactional` without `rollbackFor`
   - `@Transactional` on controller or repository instead of use case
   - Exception swallowed inside the transaction preventing rollback

   **Wiring issues**
   - `@Service`, `@Repository`, or `@Component` annotation missing
   - Class not in a package scanned by `@SpringBootApplication`
   - Circular dependency between two beans
   - Field injection ordering problem

   **JDBC / persistence issues**
   - Named parameter mismatch between SQL (`:paramName`) and `MapSqlParameterSource` key
   - `ResultSetExtractor` calling setters or public constructor instead of `reconstitute()`
   - Child rows not deleted before re-insert causing unique constraint violation
   - UUID stored as String — type mismatch in query binding
   - `Instant` stored without timezone — wrong value on read

   **DDD layering issues**
   - Domain exception not reaching global handler because it is caught in the use case
   - Domain event not published because `clearDomainEvents()` called before `publishEvent()`
   - Repository interface not found — implementation not annotated with `@Repository`
   - Use case not found — not annotated with `@Service`

   **Test issues**
   - Testcontainers datasource URL not wired via `@DynamicPropertySource`
   - `@MockBean` missing for a use case dependency in `@WebMvcTest`
   - Domain object mocked instead of tested directly

4. State the root cause clearly.

5. Provide the minimal fix with explanation.

6. Run `mvn test -Dtest={RelevantTestClass}` to verify the fix.

7. Suggest a test case that would have caught this issue earlier.
