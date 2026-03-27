#!/usr/bin/env bash
# Arrête l'application Pixel War : port-forwards, release Helm, namespace.
# Option --cluster : supprime aussi le cluster kind (libère Docker / ressources).
# Idempotent : plusieurs exécutions ne provoquent pas d'erreur bloquante.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

readonly KIND_CLUSTER_NAME="pixel-war"
readonly KIND_CONTEXT="kind-${KIND_CLUSTER_NAME}"
readonly HELM_RELEASE="pixelwar"
readonly K8S_NAMESPACE="pixelwar"
readonly ARGO_NAMESPACE="argocd"
readonly PF_STATE_DIR="${SCRIPT_DIR}/.pixelwar"
readonly PF_PID_FILE="${PF_STATE_DIR}/portforward.pids"

DELETE_CLUSTER=0
FORWARD_ONLY=0

usage() {
  cat <<EOF
Usage: $0 [options]

  Arrête port-forwards, désinstalle le release Helm, supprime le namespace (optionnellement le cluster kind).

Options :
  --forward-only   Tue uniquement les port-forwards enregistrés par run.sh --forward.
  --cluster        Supprime le cluster kind « ${KIND_CLUSTER_NAME} » (après nettoyage K8s si joignable).
  -h, --help       Cette aide.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster)       DELETE_CLUSTER=1 ;;
    --forward-only)  FORWARD_ONLY=1 ;;
    -h|--help)       usage; exit 0 ;;
    *)               echo "Option inconnue : $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

log() { printf '[stop] %s\n' "$*"; }
warn() { printf '[stop] %s\n' "$*" >&2; }

kill_port_forwards() {
  [[ -f "${PF_PID_FILE}" ]] || return 0
  while read -r pid; do
    [[ -n "${pid}" ]] || continue
    if kill -0 "${pid}" 2>/dev/null; then
      log "Arrêt du port-forward (PID ${pid})..."
      kill "${pid}" 2>/dev/null || true
    fi
  done < "${PF_PID_FILE}"
  rm -f "${PF_PID_FILE}"
}

kind_cluster_exists() {
  kind get clusters 2>/dev/null | grep -qx "${KIND_CLUSTER_NAME}"
}

k8s_api_reachable() {
  kind_cluster_exists || return 1
  kubectl --context "${KIND_CONTEXT}" cluster-info >/dev/null 2>&1
}

helm_release_present() {
  helm --kube-context "${KIND_CONTEXT}" status "${HELM_RELEASE}" -n "${K8S_NAMESPACE}" >/dev/null 2>&1
}

uninstall_helm_if_any() {
  if ! k8s_api_reachable; then
    warn "Cluster kind absent ou API Kubernetes injoignable ; saut du désinstall Helm."
    return 0
  fi
  if helm_release_present; then
    log "Désinstallation Helm : ${HELM_RELEASE} (namespace ${K8S_NAMESPACE})..."
    helm uninstall "${HELM_RELEASE}" --kube-context "${KIND_CONTEXT}" -n "${K8S_NAMESPACE}" --wait --timeout 5m
  else
    log "Aucun release Helm « ${HELM_RELEASE} » dans ${K8S_NAMESPACE}."
  fi
}

delete_namespace_if_any() {
  if ! k8s_api_reachable; then
    return 0
  fi
  if kubectl --context "${KIND_CONTEXT}" get namespace "${K8S_NAMESPACE}" >/dev/null 2>&1; then
    log "Suppression du namespace ${K8S_NAMESPACE}..."
    kubectl --context "${KIND_CONTEXT}" delete namespace "${K8S_NAMESPACE}" --wait=false >/dev/null
    log "Namespace ${K8S_NAMESPACE} en cours de suppression (asynchrone)."
  else
    log "Namespace ${K8S_NAMESPACE} déjà absent."
  fi
  if kubectl --context "${KIND_CONTEXT}" get namespace "${ARGO_NAMESPACE}" >/dev/null 2>&1; then
    log "Suppression du namespace ${ARGO_NAMESPACE}..."
    kubectl --context "${KIND_CONTEXT}" delete namespace "${ARGO_NAMESPACE}" --wait=false >/dev/null
    log "Namespace ${ARGO_NAMESPACE} en cours de suppression (asynchrone)."
  else
    log "Namespace ${ARGO_NAMESPACE} déjà absent."
  fi
}

delete_kind_cluster_if_requested() {
  [[ "${DELETE_CLUSTER}" -eq 1 ]] || return 0
  if kind get clusters 2>/dev/null | grep -qx "${KIND_CLUSTER_NAME}"; then
    log "Suppression du cluster kind « ${KIND_CLUSTER_NAME} »..."
    kind delete cluster --name "${KIND_CLUSTER_NAME}"
  else
    log "Cluster kind « ${KIND_CLUSTER_NAME} » déjà absent."
  fi
}

main() {
  kill_port_forwards

  if [[ "${FORWARD_ONLY}" -eq 1 ]]; then
    log "Arrêt des port-forwards uniquement."
    exit 0
  fi

  uninstall_helm_if_any
  delete_namespace_if_any
  delete_kind_cluster_if_requested

  log "Terminé."
}

main "$@"
