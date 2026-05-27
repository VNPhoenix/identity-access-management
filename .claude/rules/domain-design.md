---
version: 1.0
last updated: 2026-05-27
---

# Rule: Domain design

## Domain classification

Every bounded context in this codebase belongs to exactly one strategic category.
The category determines how much investment the team puts into original design,
how decisions are made when time is short, and where to buy or reuse rather than build.

| Category | Definition | Example contexts in this codebase |
|---|---|---|
| **Core** | Where the business gains competitive advantage. Invest the most design effort. Never delegate to frameworks or generics. | Identity, Authorization |
| **Supporting** | Necessary to operate but not a differentiator. Follow established patterns; avoid over-engineering. | Authentication, Audit |
| **Generic** | Commodity capability. Prefer a mature library or third-party service. Keep domain models thin. | Notification, Token Infrastructure |

Refer to `docs/domain-map.md` for the full classification and context map.

## Bounded context list

| Context | Category | Top-level package | Primary aggregate(s) |
|---|---|---|---|
| Identity | Core | `org.vnphoenix.identity` | `User` |
| Authorization | Core | `org.vnphoenix.authorization` | `Role`, `Permission`, `RoleAssignment` |
| Authentication | Supporting | `org.vnphoenix.authentication` | `RefreshToken`, `LoginAttempt` |
| Audit | Supporting | `org.vnphoenix.audit` | `AuditEvent` |
| Notification | Generic | `org.vnphoenix.notification` | `NotificationRequest` |
| Token Infrastructure | Generic (infra only) | `org.vnphoenix.infrastructure.security` | — |

## Package structure per context

Every bounded context uses the four-layer DDD structure defined in `ddd-layering.md`:

```
org.vnphoenix.{context}/
  interface/        ← controllers, DTOs, global exception handler
  application/      ← use cases, commands, queries, views
  domain/           ← aggregates, entities, value objects, events, repository interfaces
  infrastructure/   ← Spring Data JDBC entities, repositories, mappers, config adapters
```

Token Infrastructure is an exception — it has no domain layer and lives entirely in
`org.vnphoenix.infrastructure.security`.

## Cross-context integration rules

**Never import domain classes across bounded context packages.**
Authentication must not import `User` from `org.vnphoenix.identity.domain`.
It may import only primitive IDs (e.g. `UserId`) and must translate the upstream
model through an Anti-Corruption Layer in its own infrastructure layer.

**Communicate asynchronously via domain events wherever possible.**
Use Spring `ApplicationEventPublisher` in the use case after `repository.save()`.
Downstream listeners (Audit, Notification) use `@TransactionalEventListener(phase = AFTER_COMMIT)`
to guarantee at-least-once processing without coupling transactions.

**Cross-context JDBC reads are permitted at the infrastructure layer only.**
A read-side query that must join tables owned by different contexts is acceptable
in `infrastructure/persistence/` but must never surface in the domain or application
layer. The result must be translated into the consuming context's own view record.

**One aggregate transaction per use case — even across contexts.**
A use case that creates a `RoleAssignment` and simultaneously triggers an `AuditEvent`
must save the `RoleAssignment` in one transaction, then publish a domain event that
the Audit context processes in a separate transaction via its event listener.

## Domain event rules

Domain events are named in the past tense, scoped to the context that raised them,
and are immutable records:

```java
// correct — past tense, in the raising context's event package
public record UserRegistered(UserId userId, Email email, Instant occurredAt) {}

// correct
public record RoleAssignedToUser(RoleAssignmentId id, RoleId roleId, UserId userId, Instant occurredAt) {}

// wrong — imperative name
public record RegisterUser(...) {}

// wrong — cross-context reference (Authorization event importing Identity type)
public record RoleAssignedToUser(User user, ...) {}  // User is Identity's aggregate
```

## Anti-Corruption Layer rules

When a downstream context reads data owned by an upstream context, define an ACL
translator in the downstream context's `infrastructure/` package:

```
authentication/
  infrastructure/
    acl/
      IdentityAcl.java        ← translates identity.User → authentication's AuthCredential
      AuthorizationAcl.java   ← translates authorization.RoleAssignment → List<String> roles
```

The ACL class is a Spring `@Component` and may use a JDBC query directly against the
upstream context's tables. It must return the downstream context's own value types —
never the upstream aggregate or its value objects.

## Rules
- Every new class must belong to exactly one bounded context package — no class lives
  in `org.vnphoenix` directly except `Main`
- A bounded context's `domain/` package must never import from another context's
  package at any layer
- A bounded context's `application/` package must never import from another context's
  `domain/` or `application/` package
- Cross-context data access is only permitted in `infrastructure/` via ACL translators
  or read-only JDBC queries
- Domain events must be published in the use case, not in the domain aggregate's
  constructor, and not in the repository
- Do not add a new bounded context without updating `docs/domain-map.md` and this rule file
