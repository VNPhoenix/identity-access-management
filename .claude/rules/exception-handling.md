# Rule: Exception handling

## Exception hierarchy

```
RuntimeException
  └── DomainException                  ← base for all domain exceptions
        ├── OrderNotFoundException
        ├── OrderAlreadySubmittedException
        ├── InsufficientStockException
        └── CustomerNotFoundException
```

- All domain exceptions extend a base `DomainException` extending `RuntimeException`
- One exception class per distinct domain error
- Exception message includes enough context: entity type + ID + reason
- Live in `domain/` — no Spring imports

```java
public class OrderNotFoundException extends DomainException {
    public OrderNotFoundException(OrderId id) {
        super("Order not found: " + id.value());
    }
}
```

## Global handler
One `@RestControllerAdvice` in `interface/exception/`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(OrderNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse.of(404, ex.getMessage()));
    }

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<ErrorResponse> handleDomain(DomainException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
            .body(ErrorResponse.of(422, ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        var errors = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();
        return ResponseEntity.badRequest()
            .body(ErrorResponse.of(400, "Validation failed", errors));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ErrorResponse.of(500, "An unexpected error occurred"));
    }
}
```

## Error response record
```java
public record ErrorResponse(
    Instant timestamp,
    int status,
    String message,
    List<String> errors
) {
    public static ErrorResponse of(int status, String message) {
        return new ErrorResponse(Instant.now(), status, message, List.of());
    }

    public static ErrorResponse of(int status, String message, List<String> errors) {
        return new ErrorResponse(Instant.now(), status, message, errors);
    }
}
```

## Rules
- Never handle exceptions inside controllers — delegate to the global handler
- Never expose stack traces in API responses
- Never catch and swallow exceptions silently
- Log at the handler level — not at every catch site
- Throw domain exceptions from domain methods — not from use cases or controllers
