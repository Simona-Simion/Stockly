# ─── Fase 1: compilación ─────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine AS build

WORKDIR /app

# Copia el wrapper de Maven primero para aprovechar la caché de capas
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -q

# Copia el código fuente y compila
COPY src src
RUN ./mvnw clean package -DskipTests -q

# ─── Fase 2: imagen final ligera ─────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copia solo el jar del build
COPY --from=build /app/target/*.jar app.jar

# Render asigna el puerto via variable PORT
EXPOSE 8080

ENTRYPOINT ["java", \
  "-Dspring.profiles.active=prod", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
