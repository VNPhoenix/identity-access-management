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

Uses Nimbus JOSE JWT. Invalid or expired tokens must return 401 — never 500.
Roles must be loaded into the `GrantedAuthority` list so `@PreAuthorize("hasRole(...)")` works.

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
        try {
            var claims  = jwtService.validateAndExtract(token);   // throws on invalid/expired
            var userId  = claims.userId();
            var roles   = claims.roles().stream()
                .map(r -> (GrantedAuthority) new SimpleGrantedAuthority("ROLE_" + r))
                .toList();
            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                var auth = new UsernamePasswordAuthenticationToken(userId, null, roles);
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        } catch (ParseException | JOSEException | BadJOSEException e) {
            // Invalid signature, malformed token, or expired — reject with 401
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        chain.doFilter(request, response);
    }
}
```

`JwtService.validateAndExtract()` must:
1. Parse the JWT with Nimbus (`SignedJWT.parse(token)`)
2. Verify signature using the configured `JWSVerifier`
3. Validate `exp` claim — throw if expired
4. Return a typed claims record (userId, roles, etc.)

Never call `extractUserId()` before verifying the signature — Nimbus allows reading
claims from an unverified token, which is a security hole.

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
