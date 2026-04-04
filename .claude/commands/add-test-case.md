# Command: /add-test-case

Add a missing test case to the current test file: $ARGUMENTS

## Rules to follow
- `.claude/rules/code-style.md`
- `.claude/rules/testing.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/testing.md`
- `.claude/skills/maven.md`

## Steps

1. Read the current test file and understand the existing style:
   - Annotations in use (`@WebMvcTest`, `@ExtendWith`, `@SpringBootTest`)
   - MockMvc vs WebTestClient
   - Mockito vs BDDMockito style
   - Existing `@Nested` groupings

2. Add the test case described in: $ARGUMENTS
   - Place inside the correct `@Nested` class if one exists
   - Match the existing code style exactly
   - `@DisplayName` in plain English describing the scenario
   - Assert both the outcome and any side effects (saved aggregate, published event, response body)
   - Do not duplicate any existing test coverage

3. Run `mvn test -Dtest={TestClassName}` and fix any failures.

## Output
The test method added and confirmation it passes.
