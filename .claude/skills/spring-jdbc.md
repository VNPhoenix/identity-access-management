# Skill: Spring JDBC

## Template
Always use `NamedParameterJdbcTemplate`. Inject via constructor.

```java
@Repository
@RequiredArgsConstructor
public class JdbcOrderRepository implements OrderRepository {
    private final NamedParameterJdbcTemplate jdbc;
}
```

## Save (upsert)
Use ON CONFLICT upsert for all `save()` — no separate insert/update logic:

```java
@Override
public void save(Order order) {
    var sql = """
        INSERT INTO orders (id, customer_id, status, total_amount, currency, created_at, updated_at)
        VALUES (:id, :customerId, :status, :totalAmount, :currency, :createdAt, :updatedAt)
        ON CONFLICT (id) DO UPDATE SET
            status       = EXCLUDED.status,
            total_amount = EXCLUDED.total_amount,
            updated_at   = EXCLUDED.updated_at
        """;
    jdbc.update(sql, toParams(order));
    saveLines(order);
}

private MapSqlParameterSource toParams(Order order) {
    return new MapSqlParameterSource()
        .addValue("id",          order.id().value())
        .addValue("customerId",  order.customerId().value())
        .addValue("status",      order.status().name())
        .addValue("totalAmount", order.total().amount())
        .addValue("currency",    order.total().currency().getCurrencyCode())
        .addValue("createdAt",   order.createdAt())
        .addValue("updatedAt",   Instant.now());
}
```

## Find by ID with join
```java
@Override
public Optional<Order> findById(OrderId id) {
    var sql = """
        SELECT
            o.id,
            o.customer_id,
            o.status,
            o.total_amount,
            o.currency,
            o.created_at,
            ol.id         AS line_id,
            ol.product_id,
            ol.quantity,
            ol.unit_price
        FROM orders o
        LEFT JOIN order_lines ol ON ol.order_id = o.id
        WHERE o.id = :id
        """;
    var rows = jdbc.query(sql, Map.of("id", id.value()), new OrderResultSetExtractor());
    return rows.isEmpty() ? Optional.empty() : Optional.of(rows.get(0));
}
```

## ResultSetExtractor for one-to-many
Use `ResultSetExtractor` when an aggregate has child collections:

```java
@Component
public class OrderResultSetExtractor implements ResultSetExtractor<List<Order>> {

    @Override
    public List<Order> extractData(ResultSet rs) throws SQLException {
        var orders = new LinkedHashMap<UUID, Order>();
        while (rs.next()) {
            var orderId = UUID.fromString(rs.getString("id"));
            orders.computeIfAbsent(orderId, id -> reconstitute(rs));
            if (rs.getString("line_id") != null) {
                orders.get(orderId).reconstituteLine(toLine(rs));
            }
        }
        return new ArrayList<>(orders.values());
    }

    private Order reconstitute(ResultSet rs) throws SQLException {
        return Order.reconstitute(
            OrderId.of(UUID.fromString(rs.getString("id"))),
            CustomerId.of(UUID.fromString(rs.getString("customer_id"))),
            OrderStatus.valueOf(rs.getString("status")),
            Money.of(rs.getBigDecimal("total_amount"), rs.getString("currency")),
            rs.getObject("created_at", Instant.class)
        );
    }
}
```

## Paginated query
```java
var sql = """
    SELECT id, customer_id, status, total_amount, currency, created_at
    FROM orders
    WHERE customer_id = :customerId
    ORDER BY created_at DESC
    LIMIT :limit OFFSET :offset
    """;
var params = new MapSqlParameterSource()
    .addValue("customerId", customerId.value())
    .addValue("limit",      pageable.getPageSize())
    .addValue("offset",     pageable.getOffset());

var countSql = "SELECT COUNT(*) FROM orders WHERE customer_id = :customerId";
var total = jdbc.queryForObject(countSql, Map.of("customerId", customerId.value()), Long.class);
```

## Type conventions
| Java type | SQL column type | Notes |
|---|---|---|
| `UUID` | `UUID` (PostgreSQL) | Read via `rs.getObject("id", UUID.class)` |
| `Long` | `BIGINT` | DB-assigned via identity column; read via `rs.getLong("id")` |
| `Instant` | `TIMESTAMPTZ` — always UTC | |
| `Enum` | `VARCHAR` via `.name()` — never ordinal | |
| `BigDecimal` | `NUMERIC(19,4)` | |
| `boolean` | `BOOLEAN` | |

## Rules
- `NamedParameterJdbcTemplate` only — never positional `?`
- Never concatenate user input into SQL strings
- Always call `reconstitute()` factory in extractors — never setters or public constructors
- SQL only in `infrastructure/` — never in application or domain layers
