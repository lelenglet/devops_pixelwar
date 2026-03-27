### Provider Helm (aligné sur le chart Helm et run.sh / stop.sh)
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path    = var.kube_config_path
    config_context = var.kube_config_context
  }
}

# Déploiement Pixel War via le chart local pixelwar-chart/ (même source que helm upgrade --install dans run.sh).

resource "helm_release" "pixelwar" {
  name             = var.helm_release_name
  namespace        = var.helm_namespace
  create_namespace = true

  chart = "${path.module}/../pixelwar-chart"

  values = [
    file("${path.module}/../pixelwar-chart/values.yaml")
  ]

  # Surcharge pour garder cohérence avec var.helm_namespace (templates utilisent .Values.namespace).
  set {
    name  = "namespace"
    value = var.helm_namespace
    type  = "string"
  }
}

resource "kubernetes_manifest" "db_stateful_set" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/db/db-stateful-set.yaml"))
  depends_on = [kubernetes_manifest.db_secret, kubernetes_manifest.db_svc]
}

resource "kubernetes_manifest" "redis_deployment" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/redis/redis-deployment.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "redis_svc" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/redis/redis-service.yaml"))
  depends_on = [kubernetes_manifest.redis_deployment]
}

### Backend ─────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "backend_deployment" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/backend/backend-deployment.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.db_stateful_set]
}

resource "kubernetes_manifest" "backend_service" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/backend/backend-service.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.backend_deployment]
}

### Frontend ────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "frontend_deployment" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/frontend/frontend-deployment.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.backend_service]
}

resource "kubernetes_manifest" "frontend_service" {
  manifest   = yamldecode(file("${backend.local.kubernetes_path}/frontend/frontend-service.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.frontend_deployment]
  wait    = true
  timeout = var.helm_timeout_seconds
}

### Monitoring ────────────────────────────────────────────────────────────────────

resource "kubernetes_manifest" "backend_servicemonitor" {
  manifest = yamldecode(file("${backend.local.kubernetes_path}/backend/service-monitor.yml"))
  depends_on = [kubernetes_manifest.backend_service]
}

### Outputs ───────────────────────────────────────────────────────────────────
output "namespace" {
  description = "Namespace Kubernetes du déploiement Pixel War"
  value       = var.helm_namespace
}

output "helm_release_name" {
  description = "Nom du release Helm"
  value       = helm_release.pixelwar.name
}

output "port_forward_frontend" {
  description = "Commande pour exposer le frontend en local"
  value       = "kubectl port-forward svc/${var.helm_release_name}-front-service 8080:80 -n ${var.helm_namespace}"
}

output "port_forward_backend" {
  description = "Commande pour exposer le backend en local"
  value       = "kubectl port-forward svc/${var.helm_release_name}-back-service 3000:3000 -n ${var.helm_namespace}"
}
