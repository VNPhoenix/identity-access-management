# Rule: Never do

Hard stops. If any of the following is about to happen, stop and flag the issue first.

## Domain layer
- Never add Spring annotations to domain classes (`@Component`, `@Service`, `@Repository`, etc.)
- Never add JDBC, JPA, or Jackson annotations to domain classes
- Never use setters on aggregates or entities — use named domain methods
- Never expose mutable internal collections — return unmodifiable views
- Never reference another aggregate by object — use ID reference only
- Never return `null` from a public domain method — use `Optional`
- Never use a raw `Long` or `UUID` as an entity ID — always wrap in a typed value object

## Application layer
- Never put SQL or JDBC code in use cases
- Never put HTTP concepts in use cases (`HttpServletRequest`, `ResponseEntity`)
- Never call a repository from a controller — always go through a use case
- Never put business logic in a use case — delegate to the domain
- Never span two aggregate transactions in one use case

## Infrastructure layer
- Never put business logic in a JDBC repository implementation
- Never use positional `?` parameters — always use named parameters
- Never concatenate user input into SQL strings
- Never call domain constructors directly in `RowMapper` — use `reconstitute()` factory

## Interface layer
- Never return a domain object directly from a controller — map to a response DTO
- Never accept a domain object as a request body
- Never put business logic in a controller
- Never catch exceptions in a controller — let the global handler deal with them

## Testing
- Never mock domain objects — test them directly
- Never use `Thread.sleep` in tests
- Never write a test without `@DisplayName`
- Never use `@SpringBootTest` for a unit test

## General
- Never use field injection (`@Autowired` on fields)
- Never use wildcard imports
- Never hardcode secrets, API keys, or passwords
- Never log passwords, tokens, or PII
- Never expose stack traces in API responses
- Never use `spring.jpa.hibernate.ddl-auto` — this project uses JDBC and Flyway only
- Never write a migration that is not idempotent
- Never pin a Maven dependency to `LATEST` or `RELEASE`
