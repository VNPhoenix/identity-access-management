# Rule: Aggregates

## Definition
An aggregate is a cluster of domain objects treated as a single unit for data changes.
The aggregate root is the only entry point — external objects never hold references
to internal entities.

## Aggregate root
- Is an entity with a typed ID (UUID or Long) wrapped in a value object
- Enforces all invariants for itself and its children
- Is the only object repositories load and persist
- Registers domain events

```java
public class Order {               // aggregate root
    private final OrderId id;
    private final List<OrderLine> lines;   // child entities — never accessed directly from outside
    private OrderStatus status;

    private Order(OrderId id, CustomerId customerId) {
        this.id = id;
        this.customerId = customerId;
        this.lines = new ArrayList<>();
        this.status = OrderStatus.DRAFT;
        this.events = new ArrayList<>();
    }

    // static factory — named, intention-revealing
    public static Order create(CustomerId customerId) {
        var order = new Order(OrderId.generate(), customerId);
        order.registerEvent(new OrderCreated(order.id, customerId, Instant.now()));
        return order;
    }

    // domain method — enforces invariant before state change
    public void addLine(ProductId productId, Quantity quantity, Money unitPrice) {
        if (this.status != OrderStatus.DRAFT) {
            throw new OrderAlreadySubmittedException(id);
        }
        lines.add(new OrderLine(OrderLineId.generate(), productId, quantity, unitPrice));
    }

    // return unmodifiable view — never expose mutable internals
    public List<OrderLine> lines() {
        return Collections.unmodifiableList(lines);
    }
}
```

## Aggregate boundaries
- Keep aggregates small — one aggregate root + minimal child entities
- Reference other aggregates by ID only, never by object reference
- One transaction = one aggregate (do not modify two aggregates in one transaction)
- Use domain events to coordinate across aggregate boundaries

```java
// correct — reference by ID
public class Order {
    private final CustomerId customerId;   // ID reference only, not Customer object
}

// wrong — cross-aggregate object reference
public class Order {
    private final Customer customer;       // creates tight coupling
}
```

## Factory methods
- Use static factory methods instead of public constructors
- Name factories to express intent: `Order.create()`, `Order.reconstitute()`
- `create()` — new aggregate, generates ID, registers creation event
- `reconstitute()` — rebuild from persistence, no event, accepts existing ID

## Repository contract
- One repository per aggregate root — never for child entities
- Repository interface lives in `domain/repository/`
- Only two essential methods needed in most cases:
  - `save(Aggregate aggregate)`
  - `findById(AggregateId id): Optional<Aggregate>`
