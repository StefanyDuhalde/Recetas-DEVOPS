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
3. **Remediacion:** Se actualizo `spring-boot-starter-parent` a 4.0.9 y `springdoc` a 3.0.3.
4. **Resultado:** El pipeline vuelve a ejecutarse en verde de punta a punta (ver `docs/evidencias/snyk-ok.png`).

## 6. Gestion de Excepciones (Riesgo Aceptado)
Cuando una vulnerabilidad HIGH/CRITICAL **no tiene version corregida disponible**, se permite una excepcion temporal en el archivo `.snyk` bajo estas condiciones:
- Justificacion tecnica de por que no es explotable en este servicio.
- Fecha de vencimiento obligatoria (maximo 90 dias). Al vencer, Snyk vuelve a bloquear el pipeline.
- Registro en esta tabla.

| ID Snyk | Componente | Motivo | Vence |
|---------|-----------|--------|-------|
| SNYK-JAVA-ORGGLASSFISHJAXB-20883142 | jaxb-core 4.0.9 (via hibernate-core) | Sin parche disponible; la app no procesa XML externo (usa anotaciones JPA) | 2027-01-26 |

### Historial de remediacion
1. Spring Boot 3.3.5: CVE criticas en Tomcat embebido -> pipeline bloqueado.
2. Spring Boot 3.5.7: 51 vulnerabilidades (linea 3.x sin soporte OSS) -> pipeline bloqueado.
3. Spring Boot 4.0.9 + springdoc 3.0.3: 1 vulnerabilidad sin parche -> excepcion documentada -> pipeline en verde.
