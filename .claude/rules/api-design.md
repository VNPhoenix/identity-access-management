# Rule: API design

## Versioning
All endpoints versioned at path level: `/api/v1/...`

## Resource naming
- Nouns, plural, lowercase: `/api/v1/orders`, `/api/v1/customers`
- Nested for ownership: `/api/v1/customers/{customerId}/orders`
- No verbs in paths: `/api/v1/orders/{id}/cancel` is acceptable for domain actions

## HTTP verbs
| Verb     | Usage                          | Success code |
|----------|--------------------------------|--------------|
| `GET`    | Read, no side effects          | `200 OK` |
| `POST`   | Create or trigger action       | `201 Created` or `202 Accepted` |
| `PUT`    | Full replace                   | `200 OK` |
| `PATCH`  | Partial update                 | `200 OK` |
| `DELETE` | Remove                         | `204 No Content` |

## Controller structure
- One controller per aggregate resource
- Constructor injection only
- Always return `ResponseEntity`
- Accept a request DTO, build a command/query, call the use case, map result to response DTO

```java
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final PlaceOrderUseCase placeOrderUseCase;
    private final GetOrderUseCase getOrderUseCase;
    private final OrderResponseMapper mapper;

    @PostMapping
    public ResponseEntity<OrderResponse> placeOrder(
            @Valid @RequestBody PlaceOrderRequest request,
            UriComponentsBuilder uriBuilder) {

        var command = mapper.toCommand(request);
        var orderId = placeOrderUseCase.execute(command);
        var location = uriBuilder.path("/api/v1/orders/{id}").buildAndExpand(orderId.value()).toUri();
        return ResponseEntity.created(location).body(mapper.toResponse(orderId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable UUID id) {
        return getOrderUseCase.execute(new GetOrderQuery(OrderId.of(id)))
            .map(mapper::toResponse)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}
```

## Request / response DTOs
- Records only
- Live in `interface/dto/`
- Request DTOs: annotated with Bean Validation constraints
- Response DTOs: plain records — no domain objects leak through
- Always add `@Valid` on `@RequestBody`

## Pagination response
```json
{
  "content": [],
  "page": 0,
  "size": 20,
  "totalElements": 100,
  "totalPages": 5
}
```

## HTTP status codes
- `201 Created` + `Location` header on successful POST (resource creation)
- `202 Accepted` for async operations
- `204 No Content` on DELETE
- `400 Bad Request` — validation failure
- `401 Unauthorized` — not authenticated
- `403 Forbidden` — not authorized
- `404 Not Found` — resource missing
- `409 Conflict` — business rule violation or optimistic lock failure
- `422 Unprocessable Entity` — domain invariant violation
- `500 Internal Server Error` — unexpected failure, no stack trace exposed
