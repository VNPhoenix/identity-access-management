# Rule: Infrastructure layer

## Responsibilities
- Implements repository interfaces defined in the domain layer
- Owns all Spring Data JDBC annotations via separate database entity classes
- Contains mappers that convert between domain aggregates and database entities
- Contains Spring `@Configuration` and bean wiring
- Contains Flyway migration files
- No business logic

## Four-part pattern per aggregate

Each aggregate requires four infrastructure classes:

### 1. Database entity — `{Aggregate}DbEntity`

Plain class with Spring Data JDBC mapping annotations. Lives in `infrastructure/persistence/`. No domain logic.

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

    @Override public UUID getId()   { return id; }
    @Override public boolean isNew() { return isNew; }
}
```

- Uses raw Java types (`UUID`, `Long`, `String`) — no domain value objects
- `implements Persistable<UUID>` required for UUID IDs (always non-null) — `isNew` flag set by the mapper
- Long-based IDs: `Long id` (null for new entities, DB-assigned on insert) — no `Persistable` needed
- `@Transient` on `isNew` — not persisted

### 2. Spring Data JDBC repository — `{Aggregate}DbRepository`

Extends `ListCrudRepository<{Aggregate}DbEntity, UUID>`. Lives in `infrastructure/persistence/`.

```java
@Repository
interface OrderDbRepository extends ListCrudRepository<OrderDbEntity, UUID> {

    @Query("""
        SELECT * FROM orders
        WHERE customer_id = :customerId
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
        """)
    List<OrderDbEntity> findPageByCustomerId(@Param("customerId") UUID customerId,
                                              @Param("limit") int limit,
                                              @Param("offset") long offset);

    @Query("SELECT COUNT(*) FROM orders WHERE customer_id = :customerId")
    long countByCustomerId(@Param("customerId") UUID customerId);
}
```

### 3. Mapper — `{Aggregate}DbMapper`

Converts between domain aggregate and database entity. Lives in `infrastructure/persistence/`.

```java
@Component
class OrderDbMapper {

    Order toDomain(OrderDbEntity entity) {
        return Order.reconstitute(
            OrderId.of(entity.id),
            CustomerId.of(entity.customerId),
            OrderStatus.valueOf(entity.status),
            entity.lines.stream().map(this::toLine).toList(),
            entity.createdAt
        );
    }

    OrderDbEntity toEntity(Order order) {
        var entity = new OrderDbEntity();
        entity.id         = order.id().value();
        entity.customerId = order.customerId().value();
        entity.status     = order.status().name();
        entity.totalAmount = order.total().amount();
        entity.currency   = order.total().currency().getCurrencyCode();
        entity.createdAt  = order.createdAt();
        entity.updatedAt  = Instant.now();
        entity.lines      = order.lines().stream().map(this::toLineEntity).toList();
        entity.isNew      = order.isNew();
        return entity;
    }

    private OrderLine toLine(OrderLineDbEntity e) { ... }
    private OrderLineDbEntity toLineEntity(OrderLine l) { ... }
}
```

- Calls `{Aggregate}.reconstitute(...)` — never constructors, never setters
- Passes `order.isNew()` to the DB entity so Spring Data JDBC can distinguish insert from update

### 4. Repository implementation — `Jdbc{Aggregate}Repository`

Implements the domain repository interface. Lives in `infrastructure/persistence/`.

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
}
```

## Domain aggregate — `isNew()` without Spring

The domain aggregate tracks whether it was newly created (not a Spring concern):

```java
public class Order {

    private final boolean isNew;

    public static Order create(CustomerId customerId) {
        return new Order(OrderId.generate(), customerId, ..., true);
    }

    public static Order reconstitute(OrderId id, CustomerId customerId, ...) {
        return new Order(id, customerId, ..., false);
    }

    public boolean isNew() { return isNew; }
}
```

Pure Java — no Spring annotations, no `Persistable` interface on the domain class.

## Configuration
- `DataSource` auto-configured by Spring Boot — no `JdbcConfig` needed for simple setups
- Security config (`SecurityFilterChain`) lives in `infrastructure/config/`
- Enums stored via `.name()`, Instants as `TIMESTAMPTZ`

## Flyway migrations
- Files in `src/main/resources/db/migration/`
- Naming: `V{version}__{snake_case_description}.sql`
- Every migration is idempotent where possible
- Each new table: `id` (UUID or `BIGINT GENERATED ALWAYS AS IDENTITY`) `PRIMARY KEY`, `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`

## Rules
- Spring Data JDBC annotations (`@Table`, `@Id`, `@MappedCollection`, `@Transient`, `@PersistenceCreator`) only on database entity classes — never on domain classes
- Mapper always calls `reconstitute()` — never setters or public constructors on domain objects
- Domain repository interface stays in `domain/repository/` as a plain Java interface — never extends Spring interfaces
- Infrastructure classes never imported by domain or application layers
- No business logic in mappers or repository implementations