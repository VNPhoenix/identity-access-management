# Rule: Security

## Authentication
- All endpoints require authentication by default — explicitly `permitAll()` only public paths
- Public paths: `/api/v1/auth/**`, `/actuator/health`
- Use `SessionCreationPolicy.STATELESS` — no HTTP sessions
- CSRF disabled for stateless JWT APIs — document the reason in the config

## JWT
- Validate the JWT signature on every request in `JwtAuthFilter`
- Extract `userId` from claims — never trust user-supplied identity in the request body
- Never log tokens, credentials, or raw JWT strings
- Store signing secrets in environment variables — never hardcode in source

## Authorisation
- Check resource ownership in use cases — never in controllers
- Use `@PreAuthorize` for role and permission checks
- `@EnableMethodSecurity` must be present in `SecurityConfig` when `@PreAuthorize` is used
- Prefer `hasRole()` / `hasAuthority()` over raw string comparison

## Input
- Always annotate `@RequestBody` parameters with `@Valid`
- Never concatenate user input into SQL strings — use named parameters only
- Validate all value objects in their compact constructor — reject invalid state at the boundary

## Secrets and configuration
- Never hardcode secrets, API keys, or passwords in source code
- Read secrets via `@ConfigurationProperties` or `@Value("${...}")` backed by environment variables
- Never commit `.env` files or `application-local.properties` containing real credentials

## Error handling
- Never expose stack traces in API responses — catch at the global handler only
- Never leak internal class names, table names, or SQL in error messages
- Never swallow exceptions silently — always log at the handler level

## Sensitive data
- Never log passwords, tokens, PII, or secret values at any log level
- Mask or omit sensitive fields in response DTOs — internal IDs and audit fields only when necessary
- Aggregates must never expose mutable internals that could be used to bypass domain invariants