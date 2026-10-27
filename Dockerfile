# Etapa 1: Compilacion de la aplicacion Java con Maven
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B clean package -DskipTests

# Etapa 2: Imagen final liviana de ejecucion (JRE)
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copiar el archivo JAR compilado desde la etapa 1
COPY --from=build /app/target/*.jar app.jar

# Seguridad: Usuario no privilegiado (no-root)
RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 8080

# Verificacion de salud real: consulta /actuator/health (sin instalar curl)
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/8080 && printf "GET /actuator/health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n" >&3 && grep -q UP <&3' || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
