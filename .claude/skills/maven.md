# Skill: Maven

## When to use
Run Maven after every code generation or modification to confirm it compiles and tests pass.
Never present code as complete if `mvn compile` fails.

## Goal reference

| When | Goal |
|---|---|
| After generating or modifying any class | `mvn compile` |
| After writing tests | `mvn test -Dtest=ClassName` |
| Before completing a task | `mvn verify` |
| After generating a Flyway migration | `mvn flyway:migrate` |
| Investigating dependency conflicts | `mvn dependency:tree` |
| Checking for outdated dependencies | `mvn versions:display-dependency-updates` |

## Workflow
1. Write or modify code
2. `mvn compile` — fix all compilation errors before continuing
3. `mvn test -Dtest=RelevantClass` — confirm tests pass
4. `mvn verify` — full check before marking a task done

## pom.xml conventions
- All dependency versions declared in `<dependencyManagement>` — never inline
- Never use `LATEST` or `RELEASE` — always pin to an exact version
- Add a comment when introducing a new dependency explaining why
- Keep Spring Boot parent version current (`3.5.x`)
- Java version in `<properties>`: `<java.version>21</java.version>`

## Compiler config
Ensure `maven-compiler-plugin` is configured for Java 21:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <release>21</release>
        <compilerArgs>
            <arg>--enable-preview</arg>
        </compilerArgs>
    </configuration>
</plugin>
```
