# Skill: Spring Security

## Configuration
Always use the lambda DSL `SecurityFilterChain` bean in Spring Security 6.
Never extend `WebSecurityConfigurerAdapter` (removed).

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())          // stateless API — document reason
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .anyRequest().authenticated())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }
}
```

## JWT filter
```java
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        var header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }
        var token = header.substring(7);
        var userId = jwtService.extractUserId(token);
        if (userId != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            var auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        chain.doFilter(request, response);
    }
}
```

## Method security
Use `@PreAuthorize` in use cases or controllers:

```java
@PreAuthorize("hasRole('ADMIN')")
public void deleteOrder(OrderId id) { ... }

@PreAuthorize("#command.customerId().value().toString() == authentication.principal")
public OrderId execute(PlaceOrderCommand command) { ... }
```

## Rules (see security.md rule)
- Never hardcode secrets — use environment variables
- Never log tokens or credentials
- Always check resource ownership in use cases
- `@EnableMethodSecurity` must be present for `@PreAuthorize` to work
