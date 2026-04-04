# Rule: Value objects

## Definition
A value object has no identity. Two value objects are equal if all their fields are equal.
They are always immutable.

## Implementation
Use Java records for all value objects:

```java
public record Money(BigDecimal amount, Currency currency) {

    // compact constructor for validation
    public Money {
        Objects.requireNonNull(amount, "amount must not be null");
        Objects.requireNonNull(currency, "currency must not be null");
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("amount must not be negative");
        }
        amount = amount.setScale(2, RoundingMode.HALF_UP);
    }

    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("Cannot add different currencies");
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }
}
```

## ID value objects
Every aggregate and entity ID is a typed value object. Choose the backing type per aggregate:

- **UUID** — for externally visible resources, distributed generation, or when the ID must be unguessable
- **Long** — for internal/reference data, high-insert-rate tables, or where compact keys are preferred (DB assigns via identity column)

### UUID-based ID
```java
public record UserId(UUID value) {
    public UserId {
        Objects.requireNonNull(value, "UserId must not be null");
    }

    public static UserId generate()       { return new UserId(UUID.randomUUID()); }
    public static UserId of(UUID value)   { return new UserId(value); }
    public static UserId of(String value) { return new UserId(UUID.fromString(value)); }
}
```

### Long-based ID
```java
public record RoleId(Long value) {
    public RoleId {
        Objects.requireNonNull(value, "RoleId must not be null");
        if (value <= 0) throw new IllegalArgumentException("RoleId must be positive");
    }

    // No generate() — value is assigned by the database identity column
    public static RoleId of(Long value)   { return new RoleId(value); }
    public static RoleId of(String value) { return new RoleId(Long.parseLong(value)); }
}
```

## Rules
- Always validate in the compact constructor — a value object must never be in an invalid state
- Include domain behaviour as methods on the record (e.g. `Money.add()`, `Email.domain()`)
- Never use raw `UUID`, `Long`, `String`, or `BigDecimal` as entity IDs or domain primitives
- Long IDs have no `generate()` — the database assigns the value; set it via `reconstitute()` only
- Value objects live in `domain/model/` alongside the aggregates that use them
- No Spring annotations on value objects
