# Skill: Spring Data JDBC

Spring Data JDBC annotations live on **database entity classes only** — never on domain aggregates.

## Four-class pattern per aggregate

```
{Aggregate}DbEntity      ← @Table, @Id, @MappedCollection — infrastructure/persistence/
{Aggregate}DbRepository  ← extends ListCrudRepository<{Aggregate}DbEntity, UUID>
{Aggregate}DbMapper      ← converts domain ↔ DB entity
Jdbc{Aggregate}Repository implements {Aggregate}Repository  ← domain repo implementation
```

## 1. Database entity — UUID ID

```java
@Table("orders")
class OrderDbEntity implements Persistable<UUID> {

    @Id UUID id;
    UUID customerId;
    String status;
    BigDecimal totalAmount;
    String currency;
    Instant createdAt;
    Instant updatedAt;

    @MappedCollection(idColumn = "order_id")
    List<OrderLineDbEntity> lines = new ArrayList<>();

    @Transient boolean isNew;

    @Override public UUID getId()    { return id; }
    @Override public boolean isNew() { return isNew; }
}

class OrderLineDbEntity {
    UUID productId;
    int quantity;
    BigDecimal unitPrice;
}
```

## 2. Database entity — Long ID (DB-assigned)

```java
@Table("roles")
class RoleDbEntity {

    @Id Long id;   // null → insert (DB assigns); non-null → update
    String name;
    String description;
    Instant createdAt;
    Instant updatedAt;
}
```

No `Persistable` needed — null `Long` signals new entity.

## 3. Spring Data JDBC repository

```java
@Repository
interface OrderDbRepository extends ListCrudRepository<OrderDbEntity, UUID> {

    @Query("""
        SELECT *
        FROM orders
        WHERE customer_id = :customerId
        ORDER BY created_at DESC
        LIMIT  :limit
        OFFSET :offset
        """)
    List<OrderDbEntity> findPageByCustomerId(
        @Param("customerId") UUID customerId,
        @Param("limit")      int limit,
        @Param("offset")     long offset);

    @Query("SELECT COUNT(*) FROM orders WHERE customer_id = :customerId")
    long countByCustomerId(@Param("customerId") UUID customerId);
}
```

## 4. Mapper

```java
@Component
@RequiredArgsConstructor
class OrderDbMapper {

    Order toDomain(OrderDbEntity e) {
        return Order.reconstitute(
            OrderId.of(e.id),
            CustomerId.of(e.customerId),
            OrderStatus.valueOf(e.status),
            e.lines.stream().map(this::toLine).toList(),
            e.createdAt
        );
    }

    OrderDbEntity toEntity(Order o) {
        var e    = new OrderDbEntity();
        e.id          = o.id().value();
        e.customerId  = o.customerId().value();
        e.status      = o.status().name();
        e.totalAmount = o.total().amount();
        e.currency    = o.total().currency().getCurrencyCode();
        e.createdAt   = o.createdAt();
        e.updatedAt   = Instant.now();
        e.lines       = o.lines().stream().map(this::toLineEntity).toList();
        e.isNew       = o.isNew();
        return e;
    }

    private OrderLine toLine(OrderLineDbEntity e) {
        return OrderLine.reconstitute(
            ProductId.of(e.productId),
            Quantity.of(e.quantity),
            Money.of(e.unitPrice, "USD")
        );
    }

    private OrderLineDbEntity toLineEntity(OrderLine l) {
        var e       = new OrderLineDbEntity();
        e.productId = l.productId().value();
        e.quantity  = l.quantity().value();
        e.unitPrice = l.unitPrice().amount();
        return e;
    }
}
```

## 5. Domain repository implementation

```java
@Repository
@RequiredArgsConstructor
class JdbcOrderRepository implements OrderRepository {

    private final OrderDbRepository dbRepository;
    private final OrderDbMapper mapper;

    @Override
    public void save(Order order) {
        dbRepository.save(mapper.toEntity(order));
    }

    @Override
    public Optional<Order> findById(OrderId id) {
        return dbRepository.findById(id.value()).map(mapper::toDomain);
    }

    public List<Order> findPageByCustomerId(CustomerId customerId, int page, int size) {
        return dbRepository
            .findPageByCustomerId(customerId.value(), size, (long) page * size)
            .stream().map(mapper::toDomain).toList();
    }
}
```

## Domain aggregate — pure `isNew()` without Spring

```java
public class Order {

    private final boolean isNew;

    public static Order create(CustomerId customerId) {
        var order = new Order(OrderId.generate(), customerId, ..., true);
        order.registerEvent(new OrderCreated(...));
        return order;
    }

    public static Order reconstitute(OrderId id, CustomerId customerId, ...) {
        return new Order(id, customerId, ..., false);
    }

    public boolean isNew() { return isNew; }
}
```

No Spring annotations, no `Persistable`. The `isNew` field is a pure domain concept passed to the DB entity by the mapper.

## Type conventions

| Domain value object | DB entity field | DB column |
|---|---|---|
| `OrderId(UUID)` | `UUID` | `UUID` |
| `RoleId(Long)` | `Long` | `BIGINT` |
| `Instant` | `Instant` | `TIMESTAMPTZ` |
| `Enum` | `String` (`.name()`) | `VARCHAR` |
| `BigDecimal` | `BigDecimal` | `NUMERIC(19,4)` |

## Rules
- `@Table`, `@Id`, `@MappedCollection`, `@Transient`, `@PersistenceCreator` only on `{Aggregate}DbEntity` — never on domain classes
- `@Query` always uses named `:param` — never positional `?`
- Mapper always calls `reconstitute()` — never setters or public constructors on domain classes
- Domain repository interface (`{Aggregate}Repository`) is a plain Java interface — never extends Spring interfaces