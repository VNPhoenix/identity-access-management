# Rule: DDD layering

## Layer structure

```
com.example.{context}/
  interface/
    controller/       ← REST controllers
    dto/              ← request and response records
    exception/        ← @RestControllerAdvice
  application/
    usecase/          ← use case interfaces and implementations
    command/          ← command objects (write)
    query/            ← query objects (read)
  domain/
    model/            ← aggregates, entities, value objects
    event/            ← domain events
    repository/       ← repository interfaces (ports)
    service/          ← domain services (stateless domain logic)
  infrastructure/
    persistence/      ← DB entities, Spring Data JDBC repos, mappers, domain repo implementations
    config/           ← Spring @Configuration classes
    migration/        ← Flyway SQL files (resources)
```

## Dependency rule
Dependencies only point inward. Outer layers depend on inner layers — never the reverse.

```
interface → application → domain
infrastructure → domain
infrastructure → application (for wiring only)
```

- `domain` has zero Spring imports — pure Java only
- `application` may import Spring `@Transactional` and `@Service` only
- `interface` imports Spring MVC and Spring Security annotations
- `infrastructure` imports Spring Data JDBC, Spring `@Repository`, and `@Configuration`; owns all persistence annotations

## Layer responsibilities

### interface
- Deserialize HTTP request into a command or query object
- Call the use case
- Serialize the result into a response DTO
- Return `ResponseEntity`
- No business logic

### application
- Orchestrates the domain to fulfill a use case
- Owns transaction boundaries (`@Transactional`)
- Calls domain services and repositories (via interfaces)
- Publishes domain events
- No direct JDBC or SQL

### domain
- Contains all business rules and invariants
- Aggregates enforce consistency
- Repository interfaces defined here as Java interfaces (ports)
- No Spring annotations

### infrastructure
- Implements domain repository interfaces using Spring Data JDBC
- Owns all Spring Data JDBC annotations via separate database entity classes (`{Aggregate}DbEntity`)
- Maps between domain aggregates and database entities via mapper classes
- Contains custom `@Query` SQL for complex queries
- Contains Spring `@Configuration` and bean definitions
- Never contains business logic
