# IAM Domain Map

| Field | Value |
|---|---|
| **Version** | 1.0 |
| **Status** | Living document |
| **Last updated** | 2026-05-27 |
| **Author** | IAM team |
| **Scope** | VNPhoenix Identity & Access Management service |

---

## Purpose

This document establishes the strategic domain model for the IAM service. It
classifies every bounded context by business value, defines the responsibilities
and primary aggregates of each, describes how contexts relate to one another, and
maps the domain structure to the monolith package layout. All code generation,
architecture decisions, and feature-scoping conversations should reference this
document first.

---

## Domain classification overview

Eric Evans distinguishes three kinds of subdomain: **core**, **supporting**, and
**generic**. The distinction is strategic, not technical — it tells the team where to
invest in original design, where to invest in standard practice, and where to buy or
reuse rather than build.

[📊 domain-classification.mermaid](domain-classification.mermaid)

---

## Core domains

Core domains are where the business gains its competitive advantage. They are the
reason the IAM service exists. Invest the most design effort here: rich domain
models, the most experienced engineers, and the most thorough testing.

### Identity

**Bounded context:** `identity`

Identity answers the question *"Who are you?"* It is the authoritative record of every
principal in the system — the entity that all other contexts refer to by ID. Identity
owns the complete lifecycle of a user from initial registration through activation,
optional suspension, and eventual deletion. It also owns the profile data (email,
display name) and the credential record that other contexts must never access
directly.

The Identity context is a core domain because the quality of the user lifecycle model
— the invariants it enforces, the events it raises, the audit trail it produces — is
a direct expression of the product's trustworthiness. No off-the-shelf library
captures the specific rules around identity verification, account states, and data
residency that VNPhoenix requires.

**Primary aggregates**

| Aggregate | ID type | Responsibility |
|---|---|---|
| `User` | `UserId (UUID)` | Lifecycle state machine: `PENDING → ACTIVE → SUSPENDED → DELETED`. Owns `Email`, `HashedPassword`, `DisplayName`, and `UserStatus`. |
| `UserProfile` | `UserId (UUID)` | Extended profile attributes. Child of `User` or a separate aggregate depending on read/write frequency analysis. |

**Key value objects:** `Email`, `HashedPassword`, `DisplayName`, `UserStatus`

**Domain events raised**

| Event | Trigger |
|---|---|
| `UserRegistered` | A new principal completes registration |
| `UserActivated` | Email verification confirmed; account becomes active |
| `UserSuspended` | An administrator suspends the account |
| `UserReactivated` | Suspension lifted; account returns to active |
| `UserDeleted` | Account is soft-deleted or hard-deleted |
| `PasswordChanged` | User changes their own password |
| `PasswordReset` | Administrator or self-service reset issued |
| `EmailChanged` | User updates their email address |

**Invariants**

A `User` must always have a non-null, well-formed `Email`. Password storage is
always hashed — the aggregate never holds a plaintext password. State transitions
follow a strict machine: only `PENDING` users can be activated; only `ACTIVE` users
can be suspended; only `SUSPENDED` users can be reactivated; any non-`DELETED` user
can be deleted.

---

### Authorization

**Bounded context:** `authorization`

Authorization answers the question *"What are you allowed to do?"* It owns the
Role-Based Access Control (RBAC) model: the definition of roles, the set of
permissions attached to each role, and the assignment of roles to users. When any
other context needs to know whether a principal may perform an action, it asks the
Authorization context.

Authorization is a core domain because the permission model — how granular it is,
how role inheritance works, how privilege escalation is prevented — is a strategic
capability. The rules for who can assign which roles, and which permissions are
implied by a given role, are business rules that must be explicitly modeled, not
delegated to a framework.

**Primary aggregates**

| Aggregate | ID type | Responsibility |
|---|---|---|
| `Role` | `RoleId (Long)` | Named collection of permissions. Enforces that a role always has at least one permission and that its name is unique within the system. |
| `Permission` | `PermissionId (Long)` | Atomic capability grant: a `resource` (e.g. `users`) and an `action` (e.g. `READ`, `WRITE`, `DELETE`). Immutable once created. |
| `RoleAssignment` | `RoleAssignmentId (UUID)` | The binding of a `RoleId` to a `UserId`. Scoped and time-bounded where required. Enforces that a user cannot be assigned a role with higher privilege than the assigning principal holds. |

**Key value objects:** `RoleName`, `PermissionName`, `Resource`, `Action`, `Privilege`

**Domain events raised**

| Event | Trigger |
|---|---|
| `RoleCreated` | A new role is defined |
| `RoleRenamed` | A role's name is updated |
| `RoleDeleted` | A role is removed from the system |
| `PermissionGrantedToRole` | A permission is added to a role |
| `PermissionRevokedFromRole` | A permission is removed from a role |
| `RoleAssignedToUser` | A user is granted a role |
| `RoleRevokedFromUser` | A role is removed from a user |

**Invariants**

No role may grant itself — role assignment is performed by a separate `RoleAssignment`
aggregate. A user may not assign a role whose privilege level exceeds their own (privilege
escalation prevention). Permissions are defined as immutable; to change the meaning of a
permission, it must be revoked and a new one created.

---

## Supporting domains

Supporting domains are necessary for the system to function but are not where
competitive advantage is won. They follow well-understood patterns. Invest enough to
make them correct and reliable, but do not over-engineer them.

### Authentication

**Bounded context:** `authentication`

Authentication answers the question *"Can you prove who you claim to be?"* It receives
a credential pair (username/password), validates it against the Identity context's
stored hash, and — if valid — issues a signed JWT access token and a refresh token.
It also manages the token lifecycle: refresh, revocation, and expiry. It tracks
consecutive failed login attempts and enforces account lockout.

Authentication deliberately holds no authoritative data about users or permissions.
It reads `UserId` and the `HashedPassword` from Identity, reads the list of
`RoleAssignment`s from Authorization, and bundles claims from both into the issued
token. Authentication is a downstream consumer of both core contexts.

**Primary aggregates**

| Aggregate | ID type | Responsibility |
|---|---|---|
| `RefreshToken` | `RefreshTokenId (UUID)` | A single-use, time-bounded token that can be exchanged for a new access token. Tracks its own expiry and a `used` flag to prevent replay. |
| `LoginAttempt` | `LoginAttemptId (UUID)` | Consecutive failed login counter per `UserId`. Enforces lockout after N failures within a time window. |

**Key value objects:** `TokenHash`, `ExpiresAt`, `AttemptCount`, `LockoutUntil`

**Domain events raised**

| Event | Trigger |
|---|---|
| `UserAuthenticated` | Credentials validated; tokens issued |
| `AuthenticationFailed` | Invalid credentials presented |
| `AccountLockedOut` | Failed attempt threshold exceeded |
| `TokenRefreshed` | Refresh token exchanged for a new access token |
| `TokenRevoked` | Access or refresh token explicitly invalidated |
| `LogoutCompleted` | User-initiated logout; refresh token revoked |

**Invariants**

A `RefreshToken` may be used exactly once. An expired `RefreshToken` must be
rejected even if it has not been used. A locked-out account must not be authenticated
until the lockout window expires or an administrator resets it.

---

### Audit

**Bounded context:** `audit`

Audit maintains an immutable, append-only log of every security-significant event
across all bounded contexts. It is the compliance and forensics record. No existing
audit entry is ever modified or deleted. Audit consumes domain events published by
Identity, Authorization, and Authentication as an event-driven conformist: it adapts
whatever the upstream contexts emit and stores a structured, queryable record.

**Primary aggregates**

| Aggregate | ID type | Responsibility |
|---|---|---|
| `AuditEvent` | `AuditEventId (UUID)` | Immutable record of a single security event. Fields: `actorId`, `eventType`, `targetId`, `targetType`, `occurredAt`, `ipAddress`, `outcome`. Never updated after creation. |

**Key value objects:** `ActorId`, `EventType`, `TargetId`, `Outcome`, `IpAddress`

**Domain events raised**

Audit raises no domain events of its own — it is a terminal consumer.

**Invariants**

An `AuditEvent` is created in a single transaction and never mutated. The `occurredAt`
timestamp is set by the event source, not by the Audit context, to preserve the
original event time even if processing is delayed.

---

## Generic domains

Generic domains provide commodity capabilities that the system needs but that offer
no strategic differentiation. Where a mature third-party library or service exists,
prefer it over a hand-rolled implementation.

### Notification

**Bounded context:** `notification`

Notification delivers transactional messages to users in response to security events:
account activation links, password-reset links, lockout warnings, and security-change
confirmations. It is generic because the act of sending an email is not a
differentiator — the content and triggers are business rules, but the delivery
mechanism is a solved problem (SMTP, SendGrid, Amazon SES).

Notification consumes events from Identity and Authentication. It translates those
events into rendered messages and delegates actual delivery to an infrastructure
adapter. The domain model is intentionally thin.

**Primary aggregates**

| Aggregate | ID type | Responsibility |
|---|---|---|
| `NotificationRequest` | `NotificationRequestId (UUID)` | Records that a notification was requested, what template was used, the recipient, and whether delivery succeeded. Supports retry logic. |

**Key value objects:** `RecipientEmail`, `TemplateName`, `DeliveryStatus`

**Domain events raised**

| Event | Trigger |
|---|---|
| `NotificationDispatched` | Message handed to the delivery adapter |
| `NotificationFailed` | Delivery adapter reported a permanent failure |

---

### Token Infrastructure

**Package:** `infrastructure/security` (shared across bounded contexts)

Token Infrastructure is not a bounded context in the DDD sense — it does not own a
domain model. It is a shared technical capability: the plumbing that signs, parses,
and validates JWTs using the Nimbus JOSE JWT library. It exposes a `JwtService`
interface consumed by the Authentication context and the `JwtAuthFilter` in the
interface layer.

It is classified as generic because JWT signing and verification is entirely
standardised (RFC 7519). The implementation is a thin wrapper around a
well-maintained library with no bespoke business logic.

**Key components:** `JwtService`, `JwtAuthFilter`, `JwtClaimsRecord`, `SecurityConfig`

---

## Context map

The context map shows how the bounded contexts relate to each other and what
integration pattern each relationship uses.

[📊 context-map.mermaid](context-map.mermaid)

**Integration patterns used**

| Relationship | Pattern | Rationale |
|---|---|---|
| Authentication → Identity | Customer / Supplier with ACL | Authentication translates Identity's `User` model into its own `AuthCredential` concept via an Anti-Corruption Layer, isolating core domains from each other. |
| Authentication → Authorization | Customer / Supplier with ACL | Authentication reads `RoleAssignment`s to populate JWT claims. An ACL maps Authorization's model to a `List<String>` of role names. |
| Audit → Identity / Authorization / Authentication | Conformist | Audit adapts to whatever upstream contexts emit. It accepts their event schemas without imposing its own model, making it safe to evolve upstream independently. |
| Notification → Identity / Authentication | Customer / Supplier | Notification subscribes to events from upstream contexts and translates them into delivery requests. It owns its own template model and is not coupled to upstream internals. |
| Token Infrastructure → Authentication | Shared Kernel | Both share the JWT library and the `JwtClaimsRecord` definition. This is acceptable because Token Infrastructure has no domain model of its own — it is infrastructure through and through. |

---

## Package layout

In the monolithic codebase, each bounded context maps to a top-level package under
`org.vnphoenix`. Every context applies the same four-layer structure defined in
`ddd-layering.md`.

```
org.vnphoenix/
  identity/
    interface/    ← UserController, UserRequest, UserResponse
    application/  ← RegisterUserUseCase, ActivateUserUseCase, GetUserUseCase
    domain/       ← User, UserId, Email, HashedPassword, UserStatus, UserRepository
    infrastructure/ ← UserDbEntity, UserDbRepository, UserDbMapper, JdbcUserRepository

  authorization/
    interface/    ← RoleController, PermissionController, RoleAssignmentController
    application/  ← CreateRoleUseCase, AssignRoleUseCase, CheckPermissionUseCase
    domain/       ← Role, RoleId, Permission, PermissionId, RoleAssignment, ...
    infrastructure/ ← RoleDbEntity, PermissionDbEntity, RoleAssignmentDbEntity, ...

  authentication/
    interface/    ← AuthController (login, logout, refresh)
    application/  ← AuthenticateUserUseCase, RefreshTokenUseCase, RevokeTokenUseCase
    domain/       ← RefreshToken, RefreshTokenId, LoginAttempt, ...
    infrastructure/ ← RefreshTokenDbEntity, LoginAttemptDbEntity, ...

  audit/
    interface/    ← AuditController (read-only query API)
    application/  ← RecordAuditEventUseCase, QueryAuditLogUseCase
    domain/       ← AuditEvent, AuditEventId, ActorId, EventType, Outcome
    infrastructure/ ← AuditEventDbEntity, AuditEventDbRepository, ...

  notification/
    interface/    ← (no external API; internal only)
    application/  ← SendNotificationUseCase (event listener)
    domain/       ← NotificationRequest, NotificationRequestId, TemplateName
    infrastructure/ ← NotificationRequestDbEntity, SmtpNotificationAdapter, ...

  infrastructure/
    security/     ← JwtService, JwtAuthFilter, SecurityConfig  (Token Infrastructure)
    config/       ← shared Spring @Configuration beans
```

---

## Cross-cutting concerns

### Domain event bus

All domain events are published via Spring's `ApplicationEventPublisher` in the use
case after the aggregate is saved. Within a single transaction, listeners annotated
with `@TransactionalEventListener(phase = AFTER_COMMIT)` dispatch events to
downstream contexts (e.g., Audit, Notification). This ensures no event is lost if the
transaction rolls back.

### Anti-Corruption Layers

Wherever one bounded context reads from another in the same monolith, the consuming
context defines its own internal model and an ACL translator. For example,
Authentication never imports `User` from the Identity package — it imports only
`UserId` (a primitive) and calls a repository interface defined within its own domain.
The infrastructure layer wires this to the underlying shared database table via a
read-only JDBC query.

### Database ownership

Each bounded context owns its own tables. Cross-context reads that must be performed
within a single query (e.g., a join for the Audit query API) are permitted only at
the infrastructure layer and must never leak into the domain or application layers.

---

## Strategic investment guidance

| Domain | Invest in | Avoid |
|---|---|---|
| Identity | Rich aggregate model, thorough invariant tests, explicit state machine | Framework-managed lifecycle (Spring Security `UserDetails`) — keep domain pure |
| Authorization | Fine-grained permission model, privilege escalation tests, ACL translation | Hard-coding role checks in controllers — always use `@PreAuthorize` in use cases |
| Authentication | Complete token lifecycle coverage, lockout tests, Nimbus JWT integration tests | Rolling custom JWT parsing — delegate to Nimbus and `JwtService` |
| Audit | Immutable event storage, index coverage for compliance queries | Mutable audit entries; mixing audit writes with business transactions |
| Notification | Resilient retry on delivery failure, template versioning | Embedding delivery logic in the domain model |
| Token Infrastructure | Strict algorithm pinning, secret rotation procedure | Accepting `alg: none`; hardcoding signing secrets |
