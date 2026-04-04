# Command: /write-tests

Write the full test suite for the current file.

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/testing.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/testing.md`
- `.claude/skills/maven.md`

## Steps

1. Read the current file and identify its layer:
   - `domain/model/` or `domain/` → unit test, no mocks
   - `application/usecase/` → unit test with Mockito
   - `interface/controller/` → `@WebMvcTest` slice test
   - `infrastructure/persistence/` → `@SpringBootTest` + Testcontainers

2. Generate the test class in the same package under `src/test/`:

   **Domain (aggregate / value object)**
   - No Spring context, no mocks
   - Test every domain method: happy path, invariant violation, event registration
   - Test value object validation in compact constructor

   **Use case**
   - `@ExtendWith(MockitoExtension.class)`
   - Mock only repository interfaces and `ApplicationEventPublisher`
   - BDDMockito style: `given(...)` / `then(...).should(...)`
   - Cover: success path, not-found exception, domain exception paths

   **Controller**
   - `@WebMvcTest({Controller}.class)`
   - `@MockBean` for each use case
   - Test: 201/200/204 happy path, 400 validation failure, 404 not found, 422 domain error

   **JDBC repository**
   - `@SpringBootTest` + `@Testcontainers` with `PostgreSQLContainer`
   - `@DynamicPropertySource` for datasource config
   - `@Transactional` on each test for rollback
   - Test: save then findById round-trip, not found returns empty, paginated query

3. Apply to every test method:
   - `@DisplayName` — plain English describing the scenario
   - `@Nested` classes grouped by method under test
   - AssertJ assertions only

4. Run `mvn test -Dtest={TestClassName}` and fix any failures.

## Output
Full path of the test file created and a summary of cases covered.
