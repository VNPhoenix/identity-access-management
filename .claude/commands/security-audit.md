# Command: /security-audit

Audit the current file for security vulnerabilities.

## Usage

```
/security-audit
```

No arguments. Open the file to audit, then run this command.

**When to use:** Before merging any auth-related code, after adding or changing an endpoint, or when touching JWT handling or role checks. For a full pre-merge IAM audit across multiple files, prefer the `iam-security-auditor` agent.

## Examples

```
# Open JwtAuthFilter.java, then:
/security-audit

# Open UserController.java, then:
/security-audit

# Open SecurityConfig.java, then:
/security-audit
```

## Rules to follow
- `.claude/rules/ddd-layering.md`
- `.claude/rules/domain-design.md`
- `.claude/rules/application-layer.md`
- `.claude/rules/api-design.md`
- `.claude/rules/exception-handling.md`
- `.claude/rules/security.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/spring-security.md`
- `.claude/skills/spring-rest.md`
- `.claude/skills/spring-data-jdbc.md`

## Steps

1. Read the current file and identify its layer.

2. Check for the following issues by category:

   **Authentication and authorisation**
   - Endpoints missing authentication (no `@PreAuthorize` or SecurityFilterChain rule)
   - Missing `@EnableMethodSecurity` when `@PreAuthorize` is used
   - Overly broad `permitAll()` applied to non-public endpoints
   - No ownership check before returning or modifying a resource (IDOR risk)
   - Roles or permissions checked with string comparison instead of `hasRole()` / `hasAuthority()`

   **Input and data**
   - Missing `@Valid` on `@RequestBody` parameters
   - SQL built by string concatenation (injection risk)
   - Positional `?` JDBC parameters instead of named parameters
   - User-controlled data used directly in a query without binding

   **Secrets and configuration**
   - Hardcoded secrets, API keys, passwords, or tokens in source code
   - `@Value` reading secrets inline instead of `@ConfigurationProperties`
   - Secrets or tokens present in log statements

   **Error handling**
   - Stack traces exposed in API responses
   - Internal class names or infrastructure details leaked in error messages
   - Exceptions swallowed silently hiding security-relevant failures

   **Domain layer leakage**
   - Domain aggregate returned directly from controller (exposes internal model)
   - Internal IDs or audit fields exposed in response DTOs unnecessarily

3. For each issue found:
   - Severity: CRITICAL / HIGH / MEDIUM / LOW
   - Location: class and method name
   - Explanation of the vulnerability
   - Fix with corrected code

4. End with a risk summary and the top priority fix.
