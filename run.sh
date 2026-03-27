#!/usr/bin/env bash
# Démarre l'infra locale : cluster kind « pixel-war », images Docker, chart Helm, et Stack Monitoring.
# Idempotent : réexécuter met à jour le déploiement sans erreur si l'état est déjà bon.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

readonly KIND_CLUSTER_NAME="pixel-war"
readonly KIND_CONTEXT="kind-${KIND_CLUSTER_NAME}"
readonly HELM_RELEASE="pixelwar"
readonly K8S_NAMESPACE="pixelwar"
readonly FRONT_IMAGE="app-frontend:v1"
readonly BACK_IMAGE="app-backend:v1"
readonly PF_STATE_DIR="${SCRIPT_DIR}/.pixelwar"
readonly PF_PID_FILE="${PF_STATE_DIR}/portforward.pids"

SKIP_BUILD=0
WITH_FORWARD=0

usage() {
  cat <<EOF
Usage: $0 [options]

  Démarre le cluster kind, construit les images, déploie le monitoring (Prometheus/Grafana) et le chart Helm.

Options :
  --skip-build   Ne pas reconstruire les images Docker (réutilise les tags locaux).
  --forward      Lance les port-forwards (front, back, grafana) en arrière-plan
                 et enregistre les PID dans ${PF_PID_FILE}.
  -h, --help     Cette aide.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=1 ;;
    --forward)    WITH_FORWARD=1 ;;
    -h|--help)    usage; exit 0 ;;
    *)            echo "Option inconnue : $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

log() { printf '[run] %s\n' "$*"; }
die() { echo "[run] ERREUR: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Outil requis absent : $1"
}

ensure_docker_daemon() {
  docker info >/dev/null 2>&1 || die "Docker ne répond pas. Démarrez le démon Docker."
}

ensure_kind_cluster() {
  if kind get clusters 2>/dev/null | grep -qx "${KIND_CLUSTER_NAME}"; then
    log "Cluster kind « ${KIND_CLUSTER_NAME} » déjà présent."
  else
    log "Création du cluster kind « ${KIND_CLUSTER_NAME} »..."
    kind create cluster --name "${KIND_CLUSTER_NAME}" --config "${SCRIPT_DIR}/kind-config.yaml"
  fi
}

use_kubectl_context() {
  if kubectl config get-contexts -o name 2>/dev/null | grep -qx "${KIND_CONTEXT}"; then
    kubectl config use-context "${KIND_CONTEXT}" >/dev/null
    log "Contexte kubectl : ${KIND_CONTEXT} (utilisé explicitement pour les commandes suivantes)."
  else
    die "Contexte ${KIND_CONTEXT} introuvable après création du cluster."
  fi
}

kubectl_ctx() {
  kubectl --context "${KIND_CONTEXT}" "$@"
}

build_images() {
  if [[ "${SKIP_BUILD}" -eq 1 ]]; then
    log "Build Docker ignoré (--skip-build)."
    docker image inspect "${FRONT_IMAGE}" >/dev/null 2>&1 || die "Image ${FRONT_IMAGE} absente ; lancez sans --skip-build."
    docker image inspect "${BACK_IMAGE}" >/dev/null 2>&1 || die "Image ${BACK_IMAGE} absente ; lancez sans --skip-build."
    return 0
  fi
  log "Construction des images ${FRONT_IMAGE} et ${BACK_IMAGE}..."
  docker build -t "${FRONT_IMAGE}" "${SCRIPT_DIR}/frontend/"
  docker build -t "${BACK_IMAGE}" "${SCRIPT_DIR}/backend/"
}

load_images_into_kind() {
  log "Chargement des images dans le nœud kind..."
  kind load docker-image "${FRONT_IMAGE}" "${BACK_IMAGE}" --name "${KIND_CLUSTER_NAME}"
}

deploy_monitoring() {
  log "Déploiement de la stack de monitoring (kube-prometheus-stack)..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  
  helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --kube-context "${KIND_CONTEXT}" \
    --namespace monitoring \
    --create-namespace \
    --wait \
    --timeout 10m
}

deploy_helm() {
  log "Déploiement Helm (release ${HELM_RELEASE}, namespace ${K8S_NAMESPACE})..."
  helm upgrade --install "${HELM_RELEASE}" "${SCRIPT_DIR}/pixelwar-chart" \
    --kube-context "${KIND_CONTEXT}" \
    --namespace "${K8S_NAMESPACE}" \
    --create-namespace \
    --wait \
    --timeout 10m
}

verify_workloads() {
  log "Vérification des charges (filet de sécurité post-Helm)..."
  # Remarque : Adaptez le label "app=postgresdb" si nécessaire selon votre chart
  kubectl_ctx wait --for=condition=ready pod -l app=postgresdb -n "${K8S_NAMESPACE}" --timeout=180s || true
  kubectl_ctx rollout status "deployment/${HELM_RELEASE}-front-depl" -n "${K8S_NAMESPACE}" --timeout=180s
  kubectl_ctx rollout status "deployment/${HELM_RELEASE}-back-depl" -n "${K8S_NAMESPACE}" --timeout=180s
}

stop_old_port_forwards() {
  [[ -f "${PF_PID_FILE}" ]] || return 0
  while read -r pid; do
    [[ -n "${pid}" ]] || continue
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done < "${PF_PID_FILE}"
  rm -f "${PF_PID_FILE}"
}

start_port_forwards() {
  mkdir -p "${PF_STATE_DIR}"
  stop_old_port_forwards
  log "Démarrage des port-forwards (8080 → front, 3000 → back, 9000 → grafana)..."
  
  kubectl_ctx port-forward "svc/${HELM_RELEASE}-front-service" 8080:80 -n "${K8S_NAMESPACE}" >/dev/null 2>&1 &
  echo $! >> "${PF_PID_FILE}"
  
  kubectl_ctx port-forward "svc/${HELM_RELEASE}-back-service" 3000:3000 -n "${K8S_NAMESPACE}" >/dev/null 2>&1 &
  echo $! >> "${PF_PID_FILE}"

  kubectl_ctx port-forward "svc/monitoring-grafana" 9000:80 -n monitoring >/dev/null 2>&1 &
  echo $! >> "${PF_PID_FILE}"
  
  log "PID enregistrés dans ${PF_PID_FILE} (arrêt : ./stop.sh ou stop.sh --forward-only)"
}

print_summary() {
  # Récupération automatique du mot de passe Grafana
  local GRAFANA_PASS
  GRAFANA_PASS=$(kubectl_ctx --namespace monitoring get secrets monitoring-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d || echo "N/A")

  cat <<EOF

--- Infra prête (namespaces: ${K8S_NAMESPACE}, monitoring) ---
  kubectl --context ${KIND_CONTEXT} get pods -n ${K8S_NAMESPACE}

Sans l'option --forward, vous pouvez exposer localement via :
  kubectl --context ${KIND_CONTEXT} port-forward svc/${HELM_RELEASE}-front-service 8080:80 -n ${K8S_NAMESPACE} &
  kubectl --context ${KIND_CONTEXT} port-forward svc/${HELM_RELEASE}-back-service 3000:3000 -n ${K8S_NAMESPACE} &
  kubectl --context ${KIND_CONTEXT} port-forward svc/monitoring-grafana 9000:80 -n monitoring &

  Accès locaux (nécessite le port-forward actif) :
  Frontend : http://localhost:8080/
  Backend  : http://localhost:3000/
  Grafana  : http://localhost:9000/
             User: admin
             Pass: ${GRAFANA_PASS}

  Arrêt ciblé : ./stop.sh    |   Tout supprimer (y compris kind) : ./stop.sh --cluster
EOF
}

main() {
  require_cmd docker
  require_cmd kind
  require_cmd kubectl
  require_cmd helm
  ensure_docker_daemon

  ensure_kind_cluster
  use_kubectl_context
  
  build_images
  load_images_into_kind
  
  deploy_monitoring
  deploy_helm
  verify_workloads

  if [[ "${WITH_FORWARD}" -eq 1 ]]; then
    start_port_forwards
  fi

  print_summary
  log "Terminé."
}

main "$@"