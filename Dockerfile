# Etapa 1: Compilación de la aplicación Java con Maven
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Etapa 2: Imagen final liviana de ejecución (JRE)
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copiar el archivo JAR compilado desde la etapa 1
COPY --from=build /app/target/*.jar app.jar

# Seguridad: Usuario no privilegiado (no-root)
RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 8080

# Verificación de salud del contenedor
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD java -version || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
