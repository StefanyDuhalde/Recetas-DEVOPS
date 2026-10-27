# Evidencias EP2 — Ingeniería DevOps (DOY0101)

Microservicio **Recetas** (Spring Boot / Java 21) — Pipeline CI/CD con GitHub Actions.

| Fase | Indicador | Evidencia |
|------|-----------|-----------|
| 1 | IE1 — Contenedores e imágenes optimizadas | [Ir a Fase 1](#fase-1--contenedorización-ie1) |
| 2 | IE2 — Pruebas automatizadas en CI | [Ir a Fase 2](#fase-2--pruebas-automatizadas-en-ci-ie2) |
| 3 | IE3 — Seguridad y bloqueo en el pipeline | [Ir a Fase 3](#fase-3--seguridad-y-bloqueo-en-el-pipeline-ie3) |

---

## Fase 1 — Contenedorización (IE1)

**Objetivo:** construir una imagen Docker optimizada mediante *multi-stage build* (Maven → JRE), ejecutada con usuario no privilegiado y con `HEALTHCHECK` configurado.

### 1.1 Construcción exitosa de la imagen (Git Bash)
Comando ejecutado: `docker build -t recetas-app:v1 .`

![Build exitoso en Git Bash](f1-build-gitbash.png)

### 1.2 Imagen disponible en Docker Desktop

![Imagen en Docker Desktop](f1-docker-desktop.png)

### 1.3 Contenedor en ejecución — microservicio respondiendo en el puerto 8080
Comando ejecutado: `docker run -d -p 8080:8080 recetas-app:v1`

![Microservicio Recetas en localhost:8080](f1-app-8080.png)

### 1.4 Imagen ligera y estado del healthcheck
Comandos ejecutados: `docker images recetas-app` y `docker ps`

![Tamaño de la imagen y healthcheck](f1-imagen-ligera-health.png)

### 1.5 Contenedor ejecutándose con usuario no-root
Comando ejecutado: `docker exec <contenedor> whoami`

![Usuario no-root dentro del contenedor](f1-usuario-no-root.png)

---

## Fase 2 — Pruebas automatizadas en CI (IE2)

**Objetivo:** ejecutar automáticamente las pruebas (JUnit + Cucumber) con verificación de cobertura JaCoCo en cada push/PR, y validar el build de la imagen Docker solo si las pruebas pasan.

### 2.1 Pipeline en verde en GitHub Actions
Jobs: `Pruebas Automatizadas y Cobertura (IE2)` → `Validacion Docker Build`

![Pipeline en verde en GitHub Actions](f2-pipeline-verde.png)

**Resultado:** ambos jobs finalizan correctamente; el reporte de cobertura JaCoCo queda publicado como artefacto (`jacoco-coverage-report`) en cada ejecución.

---


## Fase 3 — Seguridad y bloqueo en el pipeline (IE3)

**Objetivo:** integrar análisis de seguridad automático (Dependabot + Snyk SAST/SCA) que **detenga el pipeline** ante vulnerabilidades de severidad HIGH o CRITICAL. Política completa en [`SECURITY.md`](../../SECURITY.md).

### 3.1 Bloqueo inicial (Spring Boot 3.3.5)
Snyk detectó vulnerabilidades HIGH/CRITICAL en Tomcat embebido, retornó `exit code 1` y los jobs `test-and-coverage` y `docker-build` **no se ejecutaron**.

![Pipeline bloqueado por Snyk](f3-snyk-bloqueo.png)

### 3.2 Segundo bloqueo y remediación
Con Spring Boot 3.5.7 (línea 3.x sin soporte OSS) Snyk reportó 51 vulnerabilidades. Se migró a **Spring Boot 4.0.9** y **springdoc 3.0.3**, quedando 1 vulnerabilidad sin parche disponible (XXE en `jaxb-core`).


### 3.3 Excepción controlada y pipeline en verde
La vulnerabilidad sin parche se gestionó con una excepción en `.snyk` con justificación técnica y vencimiento (2027-01-26), registrada en `SECURITY.md`. El pipeline completo pasa en verde.

![Pipeline en verde tras la remediación](f3-snyk-ok.png)

**Resultado:** el pipeline actúa como puerta de seguridad. Ningún cambio con vulnerabilidades HIGH/CRITICAL no gestionadas avanza a pruebas, build ni merge a `main`.