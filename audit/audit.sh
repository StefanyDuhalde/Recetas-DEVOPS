#!/usr/bin/env bash
# Auditoria propia de cumplimiento (IE5).
# Detiene el pipeline si encuentra:
#   1. Secretos expuestos en los archivos del repositorio.
#   2. Vulnerabilidades (CVE) de severidad CRITICAL en las dependencias.
# Deja el resultado en audit-report.md (se publica como artefacto del pipeline).
set -uo pipefail

REPORT="audit-report.md"
FALLAS=0

{
  echo "# Reporte de auditoria"
  echo ""
  echo "- Fecha (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Commit: ${GITHUB_SHA:-local}"
  echo ""
} > "$REPORT"

# ---------------------------------------------------------------------------
# 1. Secretos expuestos
# ---------------------------------------------------------------------------
echo "== 1. Busqueda de secretos =="
PATRONES=(
  'AKIA[0-9A-Z]{16}'                                   # llave de acceso AWS
  'ASIA[0-9A-Z]{16}'                                   # llave temporal AWS
  'aws_secret_access_key *[=:] *[A-Za-z0-9/+]{40}'     # secreto AWS
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'                 # llave privada
  'gh[pousr]_[A-Za-z0-9]{36}'                          # token de GitHub
  '(password|passwd|secret|api_?key|token) *[=:] *["'"'"'][^"'"'"' $]{8,}["'"'"']'  # credencial escrita en el codigo
)
HALLAZGOS=""
for p in "${PATRONES[@]}"; do
  # Solo archivos versionados; se excluye esta carpeta (contiene los patrones)
  r=$(git ls-files -z | grep -zv '^audit/' | xargs -0 grep -nIiE -- "$p" 2> /dev/null || true)
  [ -n "$r" ] && HALLAZGOS+="$r"$'\n'
done

echo "## 1. Secretos expuestos" >> "$REPORT"
if [ -n "$HALLAZGOS" ]; then
  FALLAS=$((FALLAS+1))
  echo "::error::Se encontraron posibles secretos en el repositorio"
  # Solo se muestra archivo y linea, nunca el valor
  echo "$HALLAZGOS" | cut -d: -f1,2 | sort -u | sed '/^$/d' | while read -r l; do
    echo "SECRETO DETECTADO en $l"
    echo "- ❌ Posible secreto en \`$l\`" >> "$REPORT"
  done
else
  echo "Sin secretos expuestos"
  echo "- ✅ Sin secretos expuestos" >> "$REPORT"
fi

# ---------------------------------------------------------------------------
# 2. Vulnerabilidades CRITICAL en dependencias (Snyk)
# ---------------------------------------------------------------------------
echo "== 2. Vulnerabilidades criticas =="
echo "" >> "$REPORT"
echo "## 2. Vulnerabilidades CRITICAL en dependencias" >> "$REPORT"
npx --yes snyk test --severity-threshold=critical --json > snyk-critical.json
RC=$?
case "$RC" in
  0)
    echo "Sin vulnerabilidades criticas"
    echo "- ✅ Sin vulnerabilidades CRITICAL" >> "$REPORT"
    ;;
  1)
    FALLAS=$((FALLAS+1))
    echo "::error::Se encontraron vulnerabilidades CRITICAL en las dependencias"
    jq -r '[.vulnerabilities[] | select(.severity=="critical")] | unique_by(.id)[] | "- ❌ \(.id) en \(.packageName)@\(.version): \(.title)"' \
      snyk-critical.json | tee -a "$REPORT"
    ;;
  *)
    # Si la auditoria no puede ejecutarse, se considera fallida (no se despliega a ciegas)
    FALLAS=$((FALLAS+1))
    echo "::error::No se pudo ejecutar el analisis de vulnerabilidades (codigo $RC). Revisa SNYK_TOKEN."
    echo "- ❌ El analisis no se pudo ejecutar (codigo $RC)" >> "$REPORT"
    ;;
esac

echo "" >> "$REPORT"
if [ "$FALLAS" -eq 0 ]; then
  echo "**Resultado: APROBADA**" >> "$REPORT"
else
  echo "**Resultado: RECHAZADA ($FALLAS control(es) fallido(s)). El pipeline se detiene.**" >> "$REPORT"
fi
cat "$REPORT" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
exit "$FALLAS"
