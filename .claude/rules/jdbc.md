# Rule: JDBC

## Template choice
- Always use `NamedParameterJdbcTemplate` — never positional `?` parameters
- Positional parameters are fragile and unreadable for queries with more than 2 parameters

```java
// correct
var sql = "SELECT * FROM orders WHERE customer_id = :customerId AND status = :status";
var params = Map.of("customerId", customerId.value(), "status", status.name());
jdbc.query(sql, params, rowMapper);

// wrong
var sql = "SELECT * FROM orders WHERE customer_id = ? AND status = ?";
jdbc.query(sql, rowMapper, customerId.value(), status.name());
```

## SQL formatting
Use text blocks for all multiline SQL. Align keywords:

```java
var sql = """
    SELECT
        o.id,
        o.customer_id,
        o.status,
        o.total_amount,
        o.currency,
        o.created_at,
        ol.id          AS line_id,
        ol.product_id,
        ol.quantity,
        ol.unit_price
    FROM orders o
    LEFT JOIN order_lines ol ON ol.order_id = o.id
    WHERE o.id = :id
    """;
```

## RowMapper
- One dedicated `RowMapper` or `ResultSetExtractor` per aggregate
- Use `ResultSetExtractor` when handling one-to-many joins (aggregate with child collections)
- Call the aggregate's `reconstitute()` factory — never use setters or public constructors

UUID-based extractor:
```java
@Component
public class OrderResultSetExtractor implements ResultSetExtractor<List<Order>> {

    @Override
    public List<Order> extractData(ResultSet rs) throws SQLException {
        Map<UUID, Order> orders = new LinkedHashMap<>();
        while (rs.next()) {
            var orderId = UUID.fromString(rs.getString("id"));
            var order = orders.computeIfAbsent(orderId, id -> reconstitute(rs));
            if (rs.getString("line_id") != null) {
                order.reconstituteLine(reconstituteLine(rs));
            }
        }
        return new ArrayList<>(orders.values());
    }
}
```

Long-based extractor:
```java
@Component
public class RoleResultSetExtractor implements ResultSetExtractor<List<Role>> {

    @Override
    public List<Role> extractData(ResultSet rs) throws SQLException {
        Map<Long, Role> roles = new LinkedHashMap<>();
        while (rs.next()) {
            var roleId = rs.getLong("id");
            roles.computeIfAbsent(roleId, id -> reconstitute(rs));
        }
        return new ArrayList<>(roles.values());
    }
}
```

## Parameters
- Always use `MapSqlParameterSource` or `Map.of()` for named parameters
- Extract parameter building into a private `toParams(Aggregate)` method
- Store enum values as strings (`.name()`) — never ordinals
- Store UUIDs as `UUID` type (not string) when the database supports it, otherwise as `VARCHAR(36)`
- Store Long IDs directly as `BIGINT` — call `.value()` on the ID value object
- Store `Instant` as `TIMESTAMPTZ` — always UTC

## Upsert pattern
Use database upsert for `save()` — avoids separate insert/update logic:

```sql
INSERT INTO orders (id, ...)
VALUES (:id, ...)
ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at
```

## Rules
- No SQL outside the infrastructure layer
- No `JdbcTemplate` (positional) — only `NamedParameterJdbcTemplate`
- Never concatenate user input into SQL strings
- All queries must be covered by a database index for the WHERE clause columns
- Paginated queries must include `LIMIT :limit OFFSET :offset` with explicit `ORDER BY`
