# Skill: Domain modeling

## Aggregate checklist
When creating a new aggregate, produce these files in order:

1. ID value object — `domain/model/{Aggregate}Id.java`
2. Other value objects — `domain/model/{ValueObject}.java`
3. Child entities (if any) — `domain/model/{ChildEntity}.java`
4. Domain events — `domain/event/{EventName}.java`
5. Aggregate root — `domain/model/{Aggregate}.java`
6. Repository interface — `domain/repository/{Aggregate}Repository.java`

## ID value object templates

UUID-based (externally visible, distributed, unguessable):
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

Long-based (internal/reference data, DB-assigned identity column):
```java
public record RoleId(Long value) {
    public RoleId {
        Objects.requireNonNull(value, "RoleId must not be null");
        if (value <= 0) throw new IllegalArgumentException("RoleId must be positive");
    }
    // No generate() — DB assigns the value via BIGINT GENERATED ALWAYS AS IDENTITY
    public static RoleId of(Long value)   { return new RoleId(value); }
    public static RoleId of(String value) { return new RoleId(Long.parseLong(value)); }
}
```

## Value object template
```java
public record Money(BigDecimal amount, Currency currency) {
    public Money {
        Objects.requireNonNull(amount, "amount must not be null");
        Objects.requireNonNull(currency, "currency must not be null");
        if (amount.compareTo(BigDecimal.ZERO) < 0)
            throw new IllegalArgumentException("amount must not be negative");
        amount = amount.setScale(2, RoundingMode.HALF_UP);
    }
    public static Money of(BigDecimal amount, String currencyCode) {
        return new Money(amount, Currency.getInstance(currencyCode));
    }
    public Money add(Money other) {
        if (!currency.equals(other.currency))
            throw new IllegalArgumentException("Currency mismatch");
        return new Money(amount.add(other.amount), currency);
    }
}
```

## Aggregate root template
```java
public class Order {
    private final OrderId id;
    private final CustomerId customerId;
    private final List<OrderLine> lines = new ArrayList<>();
    private OrderStatus status;
    private final Instant createdAt;
    private final List<Object> events = new ArrayList<>();

    private Order(OrderId id, CustomerId customerId, Instant createdAt) {
        this.id = id;
        this.customerId = customerId;
        this.status = OrderStatus.DRAFT;
        this.createdAt = createdAt;
    }

    public static Order create(CustomerId customerId) {
        var order = new Order(OrderId.generate(), customerId, Instant.now());
        order.events.add(new OrderCreated(order.id, customerId, order.createdAt));
        return order;
    }

    public static Order reconstitute(OrderId id, CustomerId customerId,
                                     OrderStatus status, Instant createdAt) {
        var order = new Order(id, customerId, createdAt);
        order.status = status;
        return order;
    }

    public void place() {
        if (lines.isEmpty()) throw new OrderHasNoLinesException(id);
        if (status != OrderStatus.DRAFT) throw new OrderAlreadyPlacedException(id);
        this.status = OrderStatus.PLACED;
        events.add(new OrderPlaced(id, customerId, Instant.now()));
    }

    public List<OrderLine> lines()          { return Collections.unmodifiableList(lines); }
    public void reconstituteLine(OrderLine l) { lines.add(l); }
    public List<Object> domainEvents()      { return Collections.unmodifiableList(events); }
    public void clearDomainEvents()         { events.clear(); }
    public OrderId id()                     { return id; }
    public CustomerId customerId()          { return customerId; }
    public OrderStatus status()             { return status; }
    public Instant createdAt()              { return createdAt; }
}
```

## Domain event template
```java
public record OrderPlaced(
    OrderId orderId,
    CustomerId customerId,
    Instant occurredAt
) {}
```

## Repository interface template
```java
public interface OrderRepository {
    void save(Order order);
    Optional<Order> findById(OrderId id);
}
```

## Domain service template
Stateless, pure Java, no Spring annotations:

```java
public class PricingService {
    public Money calculateTotal(List<OrderLine> lines, DiscountPolicy policy) {
        var subtotal = lines.stream()
            .map(OrderLine::subtotal)
            .reduce(Money.zero("USD"), Money::add);
        return policy.apply(subtotal);
    }
}
```
