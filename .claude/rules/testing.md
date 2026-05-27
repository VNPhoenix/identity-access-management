# Rule: Testing

## Test types per layer

| Layer | Type | Tools |
|---|---|---|
| Domain | Unit test | JUnit 5, no mocks needed |
| Application (use case) | Unit test | JUnit 5, Mockito for repositories |
| Interface (controller) | Slice test | `@WebMvcTest`, Mockito for use cases |
| Infrastructure (JDBC repo) | Integration test | `@SpringBootTest` + Testcontainers (PostgreSQL) |
| Full flow | Integration test | `@SpringBootTest` + Testcontainers + REST calls |

## Domain tests
No mocks — test aggregate and value object behaviour directly:

```java
class OrderTest {

    @Test
    @DisplayName("registers OrderPlaced event when order is placed")
    void place_registersOrderPlacedEvent() {
        var order = Order.create(CustomerId.generate());
        order.addLine(ProductId.generate(), Quantity.of(2), Money.of("10.00", "USD"));

        order.place();

        assertThat(order.domainEvents())
            .hasSize(1)
            .first().isInstanceOf(OrderPlaced.class);
    }
}
```

## Use case tests (Mockito)
Mock only the repository interfaces — never mock domain objects:

```java
@ExtendWith(MockitoExtension.class)
class PlaceOrderUseCaseTest {

    @Mock OrderRepository orderRepository;
    @Mock CustomerRepository customerRepository;
    @InjectMocks PlaceOrderUseCase useCase;

    @Test
    @DisplayName("saves order and returns order id when customer exists")
    void execute_validCommand_savesOrderAndReturnsId() {
        var customer = Customer.create(Email.of("user@example.com"));
        given(customerRepository.findById(customer.id())).willReturn(Optional.of(customer));

        var command = new PlaceOrderCommand(customer.id(), List.of(...));
        var result = useCase.execute(command);

        assertThat(result).isNotNull();
        then(orderRepository).should().save(any(Order.class));
    }
}
```

## Controller tests (@WebMvcTest)
Mock the use case — test HTTP wiring only:

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
        void placeOrder_validRequest_returns201() throws Exception {
            given(placeOrderUseCase.execute(any())).willReturn(OrderId.generate());

            mockMvc.perform(post("/api/v1/orders")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                        { "customerId": "...", "items": [] }
                        """))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"));
        }

        @Test
        @DisplayName("returns 400 when customerId is missing")
        void placeOrder_missingCustomerId_returns400() throws Exception {
            mockMvc.perform(post("/api/v1/orders")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{}"))
                .andExpect(status().isBadRequest());
        }
    }
}
```

## Repository tests (Testcontainers)

```java
@SpringBootTest
@Testcontainers
class JdbcOrderRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17");

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired JdbcOrderRepository repository;

    @Test
    @DisplayName("finds order by id after saving")
    void findById_afterSave_returnsOrder() {
        var order = Order.create(CustomerId.generate());
        repository.save(order);

        var found = repository.findById(order.id());

        assertThat(found).isPresent();
        assertThat(found.get().id()).isEqualTo(order.id());
    }
}
```

## Rules
- `@DisplayName` on every test — plain English describing the scenario
- `@Nested` classes group tests by method or scenario
- BDDMockito style: `given(...)`, `then(...).should(...)` — not `when(...)`, `verify(...)`
- AssertJ for all assertions — never JUnit `assertEquals`
- Never mock domain objects — test them directly
- Never use `Thread.sleep` — use Awaitility for async
- Test file in same package as the class under test (under `src/test/`)
- Testcontainers: reuse container across tests with `@Container static` field
