# ADR 1.0 — Dockerizing the IAM Service with Spring Boot Layertools

| Field | Value |
|---|---|
| **Version** | 1.0 |
| **Status** | Accepted |
| **Date** | 2026-05-15 |
| **Author** | IAM team |
| **Index** | [docs/adr/README.md](README.md) |

---

## Context

The IAM service is a Spring Boot 3.5 application packaged as a fat JAR and deployed
as a Docker container. During development and CI/CD, the container image is rebuilt
and pushed to a registry on every code change.

A standard fat JAR results in a **single, opaque Docker layer** containing the
application code and all of its dependencies combined (typically 80–120 MB). Because
Docker invalidates a layer the moment any byte inside it changes, every application
commit — even a one-line fix — forces a full rebuild and transfer of that entire layer.

This creates compounding problems as the team grows:

- **Slow CI/CD builds.** The dependency layer (~95% of the image) is re-downloaded,
  compiled, and re-pushed on every commit even though dependencies rarely change.
- **High registry bandwidth.** Each push transfers the full image size rather than
  only the changed portion.
- **Long deployment lag.** Container runtimes must pull the entire layer before they
  can start the updated container.
- **Poor developer experience.** Local `docker build` loops are slow because the
  Maven dependency cache inside the build stage is not reused between runs.

Spring Boot 2.3 introduced **layertools** — a built-in tool that extracts a fat JAR
into ordered layers based on change frequency. Spring Boot 3.x (used here) ships this
capability with no additional plugins required.

---

## Decision

Adopt a **multi-stage Dockerfile** that uses Spring Boot's `jarmode=layertools` to
extract the application JAR into four discrete layers, each copied separately into
the runtime image.

The four layers, ordered from most-stable to most-volatile, are:

| Layer | Contents | Change frequency |
|---|---|---|
| `dependencies/` | Released third-party libraries | Rarely — only on dependency upgrades |
| `snapshot-dependencies/` | SNAPSHOT libraries | Occasionally — during active development |
| `spring-boot-loader/` | Spring Boot loader classes | Rarely — only on Spring Boot version bumps |
| `application/` | Application classes and resources | Every commit |

Because Docker caches each `COPY` instruction as an independent layer, a typical
code-only change invalidates only the `application/` layer — a few kilobytes — while
the other three layers are served from cache. This is the canonical implementation:

```dockerfile
# ── Build stage ───────────────────────────────────────────────────────────────
FROM maven:3.9-amazoncorretto-21-alpine AS build

WORKDIR /app

# Fetch dependencies before copying source — maximises Maven cache reuse
COPY pom.xml ./
RUN mvn -q -B dependency:go-offline

COPY src/ src/
RUN mvn -q -B -DskipTests package

# Extract the fat JAR into four ordered layers
RUN java -Djarmode=layertools -jar target/*.jar extract

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

ARG IMAGE=unknown
ARG APP_VERSION=unknown
ARG BUILD_DATE=unknown
ARG GIT_SHA=unknown

LABEL org.opencontainers.image.title="${IMAGE}" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_SHA}"

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy layers in ascending volatility order — stable layers cached longest
COPY --from=build --chown=appuser:appgroup /app/dependencies/           ./
COPY --from=build --chown=appuser:appgroup /app/snapshot-dependencies/  ./
COPY --from=build --chown=appuser:appgroup /app/spring-boot-loader/     ./
COPY --from=build --chown=appuser:appgroup /app/application/            ./

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

USER appuser
EXPOSE 8080

ENTRYPOINT ["java", \
  "-XX:MaxRAMPercentage=75", \
  "-XX:+ExitOnOutOfMemoryError", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:HeapDumpPath=/tmp/heap.hprof", \
  "org.springframework.boot.loader.launch.JarLauncher"]
```

The full, authoritative Dockerfile lives at [`Dockerfile`](../../Dockerfile).

### Build workflow

The `Makefile` provides the standard build target:

```bash
# Build with the version from pom.xml (default)
make docker-build

# Build with a custom tag
make docker-build TAG=1.2.3
```

This injects `IMAGE`, `APP_VERSION`, `BUILD_DATE`, and `GIT_SHA` as build arguments
so the OCI image labels are always populated.

---

## Rationale

### Why not a single fat-JAR layer?

A naive single-layer approach — `COPY target/*.jar app.jar` — is the simplest
possible Dockerfile. It was rejected because it provides no layer caching. Every
build transfers the full image, which grows proportionally with dependencies.

### Why not Jib?

The [Jib Maven plugin](https://github.com/GoogleContainerTools/jib) builds a layered
OCI image without a Dockerfile. It was rejected for three reasons:

1. **Loss of Dockerfile control.** JVM flags, non-root user setup, health checks, and
   OCI label injection all require explicit configuration via Jib's XML DSL rather
   than the familiar Dockerfile vocabulary.
2. **Opaque security posture.** The base image and user model are chosen by the plugin
   defaults unless manually overridden, making it harder to audit security settings in
   code review.
3. **Build environment coupling.** Jib requires the Maven build to have network access
   to the container registry at build time, which complicates offline or air-gapped
   CI environments.

### Why not Cloud Native Buildpacks (Paketo)?

Buildpacks automate the entire image construction pipeline. They were rejected because:

1. **Opaque build process.** Buildpack behaviour is determined by the buildpack version
   pinned in configuration, not by readable Dockerfile instructions. This makes it
   difficult to reason about what is in the image without running the build.
2. **Harder security auditing.** The base image, OS packages, and JVM distribution are
   all chosen by the buildpack — accepting those choices requires trusting a third-party
   supply chain.
3. **Slower cold builds.** Buildpacks download and assemble layers at build time even
   when the environment is unchanged; the Maven multi-stage approach is faster when the
   Docker layer cache is warm.

### Why not a custom manual layer split?

Manually copying `WEB-INF/lib`, `WEB-INF/lib-provided`, and application classes into
separate COPY instructions would achieve a similar result but would require maintaining
the split logic by hand. Spring Boot's layertools derives the split from the JAR
metadata automatically and updates it whenever the dependency graph changes.

---

## Consequences

### Benefits

- **Cache efficiency.** A code-only change invalidates only the `application/` layer
  (typically < 1 MB). The three stable layers (~80–100 MB) are served from the Docker
  build cache on the CI runner and from the registry layer cache on the deployment
  target.
- **Faster CI/CD cycles.** Build time for a typical feature commit drops from
  "full image rebuild" to "compile + copy one layer".
- **Reduced registry bandwidth.** Incremental pushes transfer only changed layers.
  On a busy main branch this can reduce push volume by 90%+.
- **Faster deployments.** Container runtimes pull only the changed layer before
  scheduling the updated pod/container.
- **No additional tooling.** `jarmode=layertools` is bundled with the
  `spring-boot-maven-plugin` (Spring Boot ≥ 2.3). No extra Maven plugin or build
  script is required.
- **Consistent security posture.** The Dockerfile explicitly sets a non-root user,
  a known JRE base image, and JVM memory limits — all visible and reviewable.

### Trade-offs and limitations

- **Multi-stage build complexity.** The Dockerfile is longer than a single-stage
  equivalent and requires understanding the two-stage pattern to modify safely.
- **Spring Boot version floor.** `jarmode=layertools` requires Spring Boot ≥ 2.3.
  This project uses 3.5.13 — well above the floor — but a downgrade below 2.3 would
  break the Dockerfile.
- **Layer ordering is opaque.** The four-layer split is defined by Spring Boot's
  `layers.idx` inside the JAR. Custom layer configurations require adding a
  `layers.xml` descriptor and configuring it in `spring-boot-maven-plugin`; this
  is not currently needed.
- **`JarLauncher` entrypoint.** The runtime stage uses
  `org.springframework.boot.loader.launch.JarLauncher` instead of the application
  main class directly. This is the correct approach for the exploded-layer layout
  but requires the Spring Boot loader to be present in the image (it is, via the
  `spring-boot-loader/` layer).
- **No docker-compose file.** The current repository contains only a Dockerfile.
  Developers who need to run the full stack locally (app + PostgreSQL) must supply
  their own compose configuration until one is added.

---

## Impact on CI/CD

No CI/CD pipeline exists at the time of this ADR. When one is introduced, the
following guidelines apply to preserve the layertools caching benefit:

1. **Use a persistent Docker layer cache** on the CI runner (e.g., GitHub Actions
   `cache-from`/`cache-to` with `type=gha`, or a dedicated registry cache).
2. **Separate the build and push steps** so the cache is populated even on branches
   that are not pushed to the registry.
3. **Pass build arguments consistently** — `IMAGE`, `APP_VERSION`, `BUILD_DATE`,
   `GIT_SHA` — using the same logic as the `Makefile` to keep OCI labels accurate.
4. **Tag images with both the semantic version and `latest`** so deployments can pin
   to an exact version while tooling can always find the most recent build.

Example CI step (GitHub Actions):

```yaml
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: |
      vnphoenix/iam:${{ env.APP_VERSION }}
      vnphoenix/iam:latest
    build-args: |
      IMAGE=vnphoenix/iam
      APP_VERSION=${{ env.APP_VERSION }}
      BUILD_DATE=${{ env.BUILD_DATE }}
      GIT_SHA=${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## Rollback

To revert to a single fat-JAR layer, replace the layertools extraction and the four
`COPY` instructions in the runtime stage with:

```dockerfile
# In the build stage — remove the layertools extraction line
# RUN java -Djarmode=layertools -jar target/*.jar extract   ← delete this

# In the runtime stage — replace the four COPY lines with:
COPY --from=build --chown=appuser:appgroup /app/target/*.jar app.jar

# And replace the ENTRYPOINT with:
ENTRYPOINT ["java", \
  "-XX:MaxRAMPercentage=75", \
  "-XX:+ExitOnOutOfMemoryError", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:HeapDumpPath=/tmp/heap.hprof", \
  "-jar", "app.jar"]
```

This is a safe, reversible change with no impact on application behaviour.

---

## Confidence Level

**High.** The layertools approach is the recommended production pattern in the Spring
Boot documentation. The Dockerfile described in this ADR is already implemented,
validated locally, and committed to the repository. No unknowns remain.

---

## Triggers for Re-evaluation

This ADR should be revisited if any of the following occur:

- **GraalVM native image adoption.** Native compilation produces a single binary, not
  a JAR. Layertools is irrelevant in that context; a new ADR would govern the native
  image build strategy.
- **Migration to Jib or Buildpacks.** If the team decides to adopt one of the
  rejected alternatives (e.g., because Jib's Gradle/Maven integration matures or
  Paketo offers a security-auditable bill of materials), this ADR is superseded by
  the replacement.
- **Change of base image.** If `eclipse-temurin` is replaced (e.g., by a
  distroless or UBI-based image), the runtime stage needs review; the layertools
  extraction itself is unaffected.
- **Spring Boot deprecates `jarmode=layertools`.** Spring Boot's release notes
  should be checked on major version upgrades.
