# Skill: Spring REST

## Controller pattern
Follow the interface layer rules. Controllers are thin: receive request DTO,
build command/query, call use case, map to response DTO, return ResponseEntity.

```java
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final PlaceOrderUseCase placeOrderUseCase;
    private final GetOrderUseCase getOrderUseCase;
    private final ListOrdersUseCase listOrdersUseCase;
    private final CancelOrderUseCase cancelOrderUseCase;
    private final OrderRequestMapper requestMapper;
    private final OrderResponseMapper responseMapper;

    @PostMapping
    public ResponseEntity<OrderResponse> placeOrder(
            @Valid @RequestBody PlaceOrderRequest request,
            UriComponentsBuilder uriBuilder) {
        var orderId = placeOrderUseCase.execute(requestMapper.toCommand(request));
        var uri = uriBuilder.path("/api/v1/orders/{id}").buildAndExpand(orderId.value()).toUri();
        return ResponseEntity.created(uri).body(responseMapper.toResponse(orderId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable UUID id) {
        return getOrderUseCase.execute(new GetOrderQuery(OrderId.of(id)))
            .map(responseMapper::toResponse)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<Page<OrderResponse>> listOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        var result = listOrdersUseCase.execute(new ListOrdersQuery(page, size));
        return ResponseEntity.ok(result.map(responseMapper::toResponse));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelOrder(@PathVariable UUID id) {
        cancelOrderUseCase.execute(new CancelOrderCommand(OrderId.of(id)));
        return ResponseEntity.noContent().build();
    }
}
```

> **Note:** the example above injects four use cases — declare all of them as
> `private final` fields and include them in `@RequiredArgsConstructor`. Never
> reference a use case that is not declared as a constructor-injected field.

## Request DTO
```java
public record PlaceOrderRequest(
    @NotNull UUID customerId,
    @NotEmpty @Size(max = 50) List<OrderItemRequest> items
) {}
```

## Response DTO
```java
public record OrderResponse(
    UUID id,
    String customerId,
    String status,
    BigDecimal totalAmount,
    String currency,
    Instant createdAt
) {}
```

## Mapper
Use a dedicated mapper class in `interface/dto/` to convert between
request DTOs → commands and domain results → response DTOs:

```java
@Component
public class OrderRequestMapper {
    public PlaceOrderCommand toCommand(PlaceOrderRequest request) {
        return new PlaceOrderCommand(
            CustomerId.of(request.customerId()),
            request.items().stream().map(this::toItemCommand).toList()
        );
    }
}
```

## Global exception handler location
`interface/exception/GlobalExceptionHandler.java` — see `exception-handling.md` rule.
