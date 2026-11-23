# Evidencias EP3

| Indicador | Evidencia |
|-----------|-----------|
| IE1 — Monitoreo | [Ir a IE1](#ie1--monitoreo) |
| IE2 — Kubernetes en la nube | [Ir a IE2](#ie2--kubernetes-en-la-nube) |
| IE3 — Dashboard | [Ir a IE3](#ie3--dashboard) |
| IE5 — Cumplimiento | [Ir a IE5](#ie5--cumplimiento) |
| IE6 — Freno del pipeline | [Ir a IE6](#ie6--freno-del-pipeline) |

## IE2 — Kubernetes en la nube

Clúster EKS `recetas-eks` (Kubernetes 1.32):
![Clúster EKS](ep3-eks-cluster.png)

Grupo de nodos `ng-recetas`:
![Grupo de nodos](ep3-eks-grupo-nodos.png)

Nodo en estado `Ready`:
![Nodos](ep3-eks-nodos.png)

Pipeline completo en `main`, desplegado por el pipeline:
![Pipeline con deploy EKS](ep3-pipeline-eks.png)

Summary del despliegue (commit, imagen en ECR y URL del microservicio):
![Summary deploy EKS](ep3-deploy-summary.png)

## IE1 — Monitoreo

Container Insights: CPU, memoria, nodos y pods:
![Container Insights](ep3-container-insights.png)

Logs del microservicio en CloudWatch Logs:
![Logs](ep3-logs.png)

Alarmas configuradas:
![Alarmas](ep3-alarmas.png)

Caída provocada: la alarma de disponibilidad se activa y llega el correo:
![Alarma de disponibilidad](ep3-alarma-disponibilidad.png)
![Correo de alarma](ep3-correo-alarma.png)

## IE3 — Dashboard

Las 4 métricas clave: CPU/memoria, errores 5xx, cobertura y tiempo de despliegue:
![Dashboard métricas clave](ep3-dashboard-metricas.png)

Monitoreo del microservicio: disponibilidad, pods, errores en logs, alarmas y logs:
![Dashboard monitoreo](ep3-dashboard-monitoreo.png)

## IE5 — Cumplimiento

Quality Gate de SonarQube aprobado:
![SonarQube](ep3-sonarqube.png)

Branch protection de `main`:
![Ruleset](ep3-ruleset.png)

Auditoría propia aprobada:
![Auditoría](ep3-auditoria-ok.png)

## IE6 — Freno del pipeline

Producción protegida: el deploy espera la aprobación de un revisor:
![Aprobación](ep3-aprobacion.png)

Falla inyectada (secreto falso): pipeline en rojo y deploy *skipped*:
![Pipeline detenido](ep3-freno-pipeline.png)

Merge bloqueado por la branch protection:
![Merge bloqueado](ep3-merge-bloqueado.png)
