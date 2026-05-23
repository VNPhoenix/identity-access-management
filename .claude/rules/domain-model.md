# Rule: Domain model

## Entities
- Have a unique identity (UUID or Long) that persists over time
- Identity is wrapped in a typed value object — never a raw UUID or Long field
- Equality is based on identity, not field values
- Mutable state changes only through named domain methods — never via setters

```java
public class Order {
    private final OrderId id;
    private OrderStatus status;
    private final List<OrderLine> lines;

    // identity-based equality
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Order other)) return false;
        return id.equals(other.id);
    }
}
```

## Domain methods
State changes happen through explicit, intention-revealing methods:

```java
// correct — intention is clear, invariant enforced inside
public void ship(ShippingAddress address) {
    if (this.status != OrderStatus.CONFIRMED) {
        throw new OrderNotConfirmedException(id);
    }
    this.status = OrderStatus.SHIPPED;
    this.shippingAddress = address;
    registerEvent(new OrderShipped(id, address));
}

// wrong — setter exposes internals, no invariant protection
public void setStatus(OrderStatus status) { this.status = status; }
```

## Domain invariants
- Enforce all invariants in the constructor and domain methods
- Throw specific domain exceptions when invariants are violated
- Never let an aggregate reach an invalid state

## Domain events
- Register events inside aggregate methods using an internal list
- Raise events after state changes, not before
- Events are named in past tense: `OrderPlaced`, `OrderShipped`, `PaymentFailed`
- Events are immutable records

```java
public record OrderPlaced(OrderId orderId, CustomerId customerId, Instant occurredAt) {}
```

## No infrastructure in the domain
- Zero Spring imports — pure Java only
- No JPA, Spring Data, or Jackson annotations
- No `@Component`, `@Service`, `@Repository`, `@Table`, `@Id`, `@MappedCollection`
- Aggregates track newness with a plain `isNew()` method — no `Persistable` interface
