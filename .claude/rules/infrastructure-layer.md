# Rule: Infrastructure layer

## Responsibilities
- Implements repository interfaces defined in the domain layer
- Contains all JDBC and SQL code
- Contains Spring @Configuration and bean wiring
- Contains Flyway migration files
- No business logic

## Repository implementation

```java
@Repository
@RequiredArgsConstructor
public class JdbcOrderRepository implements OrderRepository {

    private final NamedParameterJdbcTemplate jdbc;
    private final OrderRowMapper rowMapper;

    @Override
    public void save(Order order) {
        // upsert pattern — insert or update
        var sql = """
            INSERT INTO orders (id, customer_id, status, total_amount, currency, created_at, updated_at)
            VALUES (:id, :customerId, :status, :totalAmount, :currency, :createdAt, :updatedAt)
            ON CONFLICT (id) DO UPDATE SET
                status = EXCLUDED.status,
                total_amount = EXCLUDED.total_amount,
                updated_at = EXCLUDED.updated_at
            """;
        jdbc.update(sql, toParams(order));
        saveLines(order);
    }

    @Override
    public Optional<Order> findById(OrderId id) {
        var sql = """
            SELECT o.*, ol.*
            FROM orders o
            LEFT JOIN order_lines ol ON ol.order_id = o.id
            WHERE o.id = :id
            """;
        var params = Map.of("id", id.value());
        var orders = jdbc.query(sql, params, rowMapper);
        return orders.isEmpty() ? Optional.empty() : Optional.of(orders.get(0));
    }

    private MapSqlParameterSource toParams(Order order) {
        return new MapSqlParameterSource()
            .addValue("id", order.id().value())
            .addValue("customerId", order.customerId().value())
            .addValue("status", order.status().name())
            .addValue("totalAmount", order.total().amount())
            .addValue("currency", order.total().currency().getCurrencyCode())
            .addValue("createdAt", order.createdAt())
            .addValue("updatedAt", Instant.now());
    }
}
```

## RowMapper
- One `RowMapper<Aggregate>` per aggregate root
- Use the aggregate's `reconstitute()` factory method to rebuild — never call constructors directly
- Handle joins by grouping rows (use `ResultSetExtractor` for one-to-many)

## Configuration
- All bean definitions in `@Configuration` classes under `infrastructure/config/`
- `DataSource`, `JdbcTemplate`, `NamedParameterJdbcTemplate` configured here
- Security config (`SecurityFilterChain`) lives here

## Flyway migrations
- Files in `src/main/resources/db/migration/`
- Naming: `V{version}__{snake_case_description}.sql`
- Every migration is idempotent where possible
- Each new table includes: `id` (UUID or `BIGINT GENERATED ALWAYS AS IDENTITY`) `PRIMARY KEY`, `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`

## Rules
- Infrastructure classes never imported by domain or application layers
- No business logic in repository implementations
- All SQL in the infrastructure layer — no SQL strings in application or domain
