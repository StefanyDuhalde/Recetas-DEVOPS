#!/usr/bin/env bash
# Observabilidad en Amazon CloudWatch (IE1 / IE3).
# Lo ejecuta el pipeline en cada despliegue. Es idempotente: si algo ya existe, lo actualiza.
#   1. Retencion de los logs del cluster (Container Insights)
#   2. Metrica de errores a partir de los logs del microservicio
#   3. Topico SNS + correo para las alarmas
#   4. Alarmas: disponibilidad, errores 5xx, errores en logs, CPU y memoria
#   5. Dashboard "Recetas-DevOps" (desde monitoring/dashboard-recetas.json)
# Variables: CLUSTER_NAME, AWS_REGION, ELB_NAME (Load Balancer del Service). Opcional: ALERT_EMAIL.
set -euo pipefail

: "${CLUSTER_NAME:?Falta CLUSTER_NAME}"
: "${AWS_REGION:?Falta AWS_REGION}"
: "${ELB_NAME:?Falta ELB_NAME}"
export AWS_DEFAULT_REGION="$AWS_REGION"

DIR="$(cd "$(dirname "$0")" && pwd)"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LOG_GROUP="/aws/containerinsights/${CLUSTER_NAME}/application"

echo "== 1. Retencion de logs (7 dias) =="
aws logs put-retention-policy --log-group-name "$LOG_GROUP" --retention-in-days 7

echo "== 2. Metrica de errores en los logs del microservicio =="
aws logs put-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name recetas-errores-log \
  --filter-pattern '"ERROR" "recetas-svc"' \
  --metric-transformations metricName=ErroresLog,metricNamespace=Recetas/App,metricValue=1,defaultValue=0

echo "== 3. Topico SNS para alertas =="
TOPIC_ARN=$(aws sns create-topic --name recetas-alertas --query TopicArn --output text)
if [ -n "${ALERT_EMAIL:-}" ]; then
  YA=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
    --query "length(Subscriptions[?Endpoint=='${ALERT_EMAIL}'])" --output text)
  if [ "$YA" = "0" ]; then
    aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "$ALERT_EMAIL" > /dev/null
    echo "Suscripcion enviada a $ALERT_EMAIL: confirmala desde el correo"
  fi
fi

echo "== 4. Alarmas =="
ELB_DIM="Name=LoadBalancerName,Value=$ELB_NAME"
POD_DIMS="Name=ClusterName,Value=$CLUSTER_NAME Name=Namespace,Value=recetas Name=PodName,Value=recetas-svc"

aws cloudwatch put-metric-alarm --alarm-name recetas-disponibilidad \
  --alarm-description "El Load Balancer no tiene destinos saludables: el microservicio no esta disponible" \
  --namespace AWS/ELB --metric-name HealthyHostCount --dimensions $ELB_DIM \
  --statistic Minimum --comparison-operator LessThanThreshold --threshold 1 \
  --period 60 --evaluation-periods 2 --treat-missing-data breaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --alarm-name recetas-errores-5xx \
  --alarm-description "El microservicio respondio errores HTTP 5xx" \
  --namespace AWS/ELB --metric-name HTTPCode_Backend_5XX --dimensions $ELB_DIM \
  --statistic Sum --comparison-operator GreaterThanOrEqualToThreshold --threshold 1 \
  --period 60 --evaluation-periods 1 --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --alarm-name recetas-errores-log \
  --alarm-description "Se registraron lineas ERROR en los logs del microservicio" \
  --namespace Recetas/App --metric-name ErroresLog \
  --statistic Sum --comparison-operator GreaterThanOrEqualToThreshold --threshold 1 \
  --period 300 --evaluation-periods 1 --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --alarm-name recetas-cpu-alta \
  --alarm-description "CPU de los pods sobre el 80% de su limite" \
  --namespace ContainerInsights --metric-name pod_cpu_utilization_over_pod_limit --dimensions $POD_DIMS \
  --statistic Average --comparison-operator GreaterThanThreshold --threshold 80 \
  --period 300 --evaluation-periods 2 --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --alarm-name recetas-memoria-alta \
  --alarm-description "Memoria de los pods sobre el 85% de su limite" \
  --namespace ContainerInsights --metric-name pod_memory_utilization_over_pod_limit --dimensions $POD_DIMS \
  --statistic Average --comparison-operator GreaterThanThreshold --threshold 85 \
  --period 300 --evaluation-periods 2 --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"
echo "5 alarmas creadas/actualizadas"

echo "== 5. Dashboard Recetas-DevOps =="
BODY=$(sed -e "s|__REGION__|$AWS_REGION|g" -e "s|__CLUSTER__|$CLUSTER_NAME|g" \
           -e "s|__ELB__|$ELB_NAME|g" -e "s|__ACCOUNT__|$ACCOUNT_ID|g" "$DIR/dashboard-recetas.json")
aws cloudwatch put-dashboard --dashboard-name Recetas-DevOps --dashboard-body "$BODY" > /dev/null
echo "https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards/dashboard/Recetas-DevOps"
