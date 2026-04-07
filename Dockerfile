FROM maven:3.9-amazoncorretto-21-alpine AS build

WORKDIR /app

COPY pom.xml ./

RUN mvn -q -B dependency:go-offline

COPY src/ src/

RUN mvn -q -B -DskipTests package

RUN java -Djarmode=layertools -jar target/*.jar extract

# ── Runtime ──────────────────────────────────────────────
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

COPY --from=build --chown=appuser:appgroup /app/dependencies/ ./
COPY --from=build --chown=appuser:appgroup /app/snapshot-dependencies/ ./
COPY --from=build --chown=appuser:appgroup /app/spring-boot-loader/ ./
COPY --from=build --chown=appuser:appgroup /app/application/ ./

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