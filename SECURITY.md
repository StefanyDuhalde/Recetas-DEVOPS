# Politica de Seguridad y Gobernanza DevSecOps

## 1. Escaneo de Dependencias (Dependabot)
- Se ejecuta semanalmente sobre el ecosistema `maven` y `github-actions`.
- Genera Pull Requests automaticos ante vulnerabilidades detectadas en bibliotecas de terceros.

## 2. Analisis SAST y SCA (Snyk)
- Integrado en el pipeline de GitHub Actions como puerta de enlace obligatoria (`security-analysis`).
- Se analiza el codigo fuente (`snyk code test`) y el arbol de dependencias Maven (`snyk test`).

## 3. Politica de Bloqueo del Pipeline
- **Umbral de Corte:** `--severity-threshold=high`.
- **Regla:** Si se detecta al menos una vulnerabilidad clasificada como **HIGH** o **CRITICAL**, Snyk retorna un codigo de salida distinto de cero (`exit code != 0`).
- **Efecto:** El job `security-analysis` falla, cancelando inmediatamente la ejecucion de `test-and-coverage` y `docker-build`, e impidiendo la fusion (Merge) hacia la rama `main`.

## 4. Parametros de Escalabilidad y Recursos
- **Replicas iniciales:** 2 instancias balanceadas.
- **Límites de Recursos por Contenedor:**
  - `CPU Limit`: 0.5 cores (50% de 1 vCPU).
  - `Memory Limit`: 512 MB RAM.
  - `CPU Reservation`: 0.25 cores.
  - `Memory Reservation`: 256 MB RAM.

## 5. Evidencia del Bloqueo y Remediacion
1. **Deteccion:** En el primer run del job `security-analysis`, `snyk test` detectó vulnerabilidades HIGH/CRITICAL en dependencias transitivas de Spring Boot 3.3.5 (Tomcat embebido).
2. **Bloqueo:** Snyk retorno `exit code 1`, el job fallo y se cancelaron `test-and-coverage` y `docker-build` (ver `docs/evidencias/snyk-bloqueo.png`).
3. **Remediacion:** Se actualizo `spring-boot-starter-parent` a 3.5.7 y `springdoc` a 2.8.9.
4. **Resultado:** El pipeline vuelve a ejecutarse en verde de punta a punta (ver `docs/evidencias/snyk-ok.png`).
