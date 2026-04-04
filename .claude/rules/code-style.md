# Rule: Code style

## Java 21 features
Use modern Java wherever it improves clarity:
- Records for immutable DTOs, commands, queries, and value objects
- Sealed classes + pattern matching for closed domain hierarchies
- Pattern matching `instanceof` — eliminate redundant casts
- Text blocks for multiline SQL strings
- `var` for local variables when the type is obvious from the right-hand side
- Virtual threads are available — do not block the carrier thread unnecessarily

## Naming
- Classes: PascalCase noun — `Order`, `OrderRepository`, `PlaceOrderUseCase`
- Methods: camelCase verb — `placeOrder()`, `findById()`, `markAsShipped()`
- Packages: lowercase, singular — `domain`, `application`, `infrastructure`, `interface`
- No abbreviations: `repository` not `repo`, `service` not `svc`, `application` not `app`
- Boolean methods/fields: prefix `is`, `has`, `can` — `isActive()`, `hasItems()`
- Constants: UPPER_SNAKE_CASE — `MAX_RETRY_COUNT`

## Imports
- No wildcard imports (`import com.example.*`)
- No unused imports
- Order: static → `java.*` → `jakarta.*` → Spring → third-party → internal

## Method and class size
- Max method length: 20 lines — extract private helpers if exceeded
- Max class length: 200 lines — split by responsibility if exceeded
- One public responsibility per class

## Immutability
- Prefer `final` fields everywhere
- Use unmodifiable collections: `List.of()`, `Map.of()`, `Set.copyOf()`
- Never return mutable internal collections — always return a copy or unmodifiable view
- Never return `null` from a public method — use `Optional` for absent values

## Miscellaneous
- No magic numbers or strings — extract to named constants
- Use `Optional` as return type only — never as parameter or field type
- Prefer early return over nested `if` blocks
- Every public class and method must have a meaningful name — Javadoc only when the name is insufficient
