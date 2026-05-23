# Rule: Spring Data JDBC

## Separation of concerns

Spring Data JDBC annotations live exclusively on **database entity classes** in `infrastructure/persistence/` — never on domain classes.

| Class | Location | Spring annotations? |
|---|---|---|
| `Order` (domain aggregate) | `domain/model/` | None — pure Java |
| `OrderDbEntity` (persistence model) | `infrastructure/persistence/` | `@Table`, `@Id`, `@MappedCollection` |
| `OrderDbRepository` (Spring Data JDBC repo) | `infrastructure/persistence/` | `@Repository` |
| `JdbcOrderRepository` (domain repo impl) | `infrastructure/persistence/` | `@Repository` |

## Database entity class

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
```

- Uses raw Java types (`UUID`, `Long`, `String`, `Instant`, `BigDecimal`) — no domain value objects
- Child DB entities do not need `@Id`

## New vs. existing detection

| ID type | DB entity `@Id` field | `Persistable` needed? |
|---|---|---|
| UUID (domain-generated) | `UUID id` — always non-null | Yes — `isNew` flag set by the mapper from `order.isNew()` |
| Long (DB-assigned identity) | `Long id` — null for new entities | No — null ID signals insert |

## Spring Data JDBC repository

Typed to the database entity, not the domain aggregate:

```java
@Repository
interface OrderDbRepository extends ListCrudRepository<OrderDbEntity, UUID> {

    @Query("""
        SELECT * FROM orders
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

Always use named parameters. Never positional `?`.

## Domain aggregate — `isNew()` without Spring

The domain aggregate has a pure Java `isNew()` method:

```java
public class Order {
    private final boolean isNew;

    public static Order create(...) {
        return new Order(..., true);   // newly created
    }

    public static Order reconstitute(...) {
        return new Order(..., false);  // loaded from DB
    }

    public boolean isNew() { return isNew; }
}
```

No `Persistable`, no `@Transient`, no Spring imports in the domain class.

## Mapper

Mapper converts between domain aggregate and DB entity in `infrastructure/persistence/`:

```java
@Component
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
        var e = new OrderDbEntity();
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
}
```

## Type conventions

| Java domain type | DB entity field type | DB column type |
|---|---|---|
| `OrderId(UUID)` | `UUID` | `UUID` (PostgreSQL) |
| `RoleId(Long)` | `Long` | `BIGINT` |
| `Instant` | `Instant` | `TIMESTAMPTZ` |
| `Enum` | `String` via `.name()` | `VARCHAR` |
| `BigDecimal` | `BigDecimal` | `NUMERIC(19,4)` |

## Rules
- Never place `@Table`, `@Id`, `@MappedCollection`, `@Transient`, `@PersistenceCreator` on domain classes
- Never use positional `?` in `@Query` — always named `:param`
- Never concatenate user input into SQL strings
- Never write custom `save()` or `findById()` in `{Aggregate}DbRepository` — inherit from `ListCrudRepository`
- Mapper always calls `reconstitute()` on domain — never setters or public constructors
- Domain repository interface (`{Aggregate}Repository`) in `domain/repository/` is a plain Java interface