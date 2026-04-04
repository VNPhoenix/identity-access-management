# Rule: Application layer

## Responsibilities
- Orchestrates the domain to fulfill a single use case
- Loads aggregates via repository interfaces
- Calls domain methods
- Saves modified aggregates
- Publishes domain events
- Owns transaction boundaries

## Use case structure
One class per use case. Named after the action: `PlaceOrderUseCase`, `CancelOrderUseCase`.

```java
@Service
@RequiredArgsConstructor
public class PlaceOrderUseCase {

    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public OrderId execute(PlaceOrderCommand command) {
        var customer = customerRepository.findById(command.customerId())
            .orElseThrow(() -> new CustomerNotFoundException(command.customerId()));

        var order = Order.create(customer.id());

        command.items().forEach(item ->
            order.addLine(item.productId(), item.quantity(), item.unitPrice())
        );

        order.place();
        orderRepository.save(order);

        order.domainEvents().forEach(eventPublisher::publishEvent);

        return order.id();
    }
}
```

## Commands and queries
- Commands: represent write intent — immutable records, named in imperative: `PlaceOrderCommand`
- Queries: represent read intent — immutable records, named with `Query` suffix: `GetOrderQuery`
- Commands and queries live in `application/command/` and `application/query/`

```java
public record PlaceOrderCommand(
    CustomerId customerId,
    List<OrderItemCommand> items
) {}

public record OrderItemCommand(
    ProductId productId,
    Quantity quantity,
    Money unitPrice
) {}
```

## Transaction rules
- `@Transactional` on use case `execute()` methods — never on domain or repository
- Read-only use cases: `@Transactional(readOnly = true)`
- One transaction per use case execution — never span two use cases in one transaction

## Rules
- No SQL or JDBC in the application layer
- No HTTP concepts (no `HttpServletRequest`, no `ResponseEntity`)
- No direct access to repositories from controllers — always go through a use case
- Use case returns a typed result or void — never returns a domain object directly to the interface layer
- Map domain objects to response DTOs in the interface layer, not here
