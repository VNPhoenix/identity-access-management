# Skill: Testing

## Test type decision

| What to test | Test type | Annotations |
|---|---|---|
| Aggregate / value object | Unit | JUnit 5 only — no mocks |
| Use case | Unit | `@ExtendWith(MockitoExtension.class)` |
| Controller | Web slice | `@WebMvcTest` |
| JDBC repository | Integration | `@SpringBootTest` + `@Testcontainers` |
| Full vertical slice | Integration | `@SpringBootTest` + `@Testcontainers` |

## Domain unit test
No Spring context, no mocks — test the domain directly:

```java
class OrderTest {

    @Test
    @DisplayName("transitions to PLACED status when order has lines")
    void place_withLines_transitionsToPlaced() {
        var order = Order.create(CustomerId.generate());
        order.addLine(ProductId.generate(), Quantity.of(1), Money.of("10.00", "USD"));

        order.place();

        assertThat(order.status()).isEqualTo(OrderStatus.PLACED);
    }

    @Test
    @DisplayName("throws when placing an order with no lines")
    void place_withNoLines_throws() {
        var order = Order.create(CustomerId.generate());

        assertThatThrownBy(order::place)
            .isInstanceOf(OrderHasNoLinesException.class);
    }

    @Test
    @DisplayName("registers OrderPlaced event on place()")
    void place_registersOrderPlacedEvent() {
        var order = Order.create(CustomerId.generate());
        order.addLine(ProductId.generate(), Quantity.of(1), Money.of("10.00", "USD"));

        order.place();

        assertThat(order.domainEvents())
            .hasSize(2)
            .last().isInstanceOf(OrderPlaced.class);
    }
}
```

## Use case unit test (Mockito)
Mock only repository interfaces — never mock domain objects:

```java
@ExtendWith(MockitoExtension.class)
class PlaceOrderUseCaseTest {

    @Mock OrderRepository orderRepository;
    @Mock CustomerRepository customerRepository;
    @Mock ApplicationEventPublisher eventPublisher;
    @InjectMocks PlaceOrderUseCase useCase;

    @Test
    @DisplayName("saves order and returns id when customer exists")
    void execute_customerExists_savesAndReturnsId() {
        var customer = Customer.create(Email.of("user@example.com"));
        given(customerRepository.findById(customer.id()))
            .willReturn(Optional.of(customer));

        var result = useCase.execute(new PlaceOrderCommand(customer.id(), List.of()));

        assertThat(result).isNotNull();
        then(orderRepository).should().save(any(Order.class));
    }

    @Test
    @DisplayName("throws CustomerNotFoundException when customer does not exist")
    void execute_customerNotFound_throws() {
        var customerId = CustomerId.generate();
        given(customerRepository.findById(customerId)).willReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(new PlaceOrderCommand(customerId, List.of())))
            .isInstanceOf(CustomerNotFoundException.class);
    }
}
```

## Controller web slice test
```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean PlaceOrderUseCase placeOrderUseCase;

    @Nested
    @DisplayName("POST /api/v1/orders")
    class PlaceOrder {

        @Test
        @DisplayName("returns 201 and Location header when request is valid")
        void validRequest_returns201() throws Exception {
            given(placeOrderUseCase.execute(any())).willReturn(OrderId.generate());

            mockMvc.perform(post("/api/v1/orders")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                        {
                          "customerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                          "items": []
                        }
                        """))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"));
        }

        @Test
        @DisplayName("returns 400 when customerId is missing")
        void missingCustomerId_returns400() throws Exception {
            mockMvc.perform(post("/api/v1/orders")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{}"))
                .andExpect(status().isBadRequest());
        }
    }
}
```

## JDBC repository integration test (Testcontainers)
```java
@SpringBootTest
@Testcontainers
class JdbcOrderRepositoryTest {

    @Container
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void datasourceProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",      postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired JdbcOrderRepository repository;

    @Test
    @DisplayName("finds order with lines after saving")
    void findById_afterSave_returnsOrderWithLines() {
        var order = Order.create(CustomerId.generate());
        order.addLine(ProductId.generate(), Quantity.of(2), Money.of("15.00", "USD"));
        repository.save(order);

        var found = repository.findById(order.id());

        assertThat(found).isPresent();
        assertThat(found.get().lines()).hasSize(1);
    }

    @Test
    @DisplayName("returns empty when order does not exist")
    void findById_notFound_returnsEmpty() {
        assertThat(repository.findById(OrderId.generate())).isEmpty();
    }
}
```

## Conventions
- BDDMockito style: `given(...)` / `then(...).should(...)` — not `when()` / `verify()`
- AssertJ for all assertions — never raw JUnit `assertEquals`
- `@DisplayName` on every test — plain English
- `@Nested` groups tests by method or scenario
- `@Container static` for Testcontainers — reuse across tests in the class
- Test file in same package as class under test (under `src/test/`)
- Never use `Thread.sleep` — use Awaitility for async assertions
