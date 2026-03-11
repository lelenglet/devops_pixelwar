### Provider ────────────────────────────────────────────────────────────
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kube_config_path
  config_context = var.kube_config_context
}

locals {
  kubernetes_path = "${path.module}/../kubernetes"
}

# Déploiement Pixel War : namespace, DB (PostgreSQL), backend, frontend.
# Les manifests sont chargés depuis ../kubernetes/ et appliqués dans l'ordre des dépendances.

### Namespace ─────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "namespace" {
  manifest = yamldecode(file("${local.kubernetes_path}/namespace.yaml"))
}

### Database ─────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "db_secret" {
  manifest   = yamldecode(file("${local.kubernetes_path}/db/db-secret.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "db_svc" {
  manifest   = yamldecode(file("${local.kubernetes_path}/db/db-svc.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "db_stateful_set" {
  manifest   = yamldecode(file("${local.kubernetes_path}/db/db-stateful-set.yaml"))
  depends_on = [kubernetes_manifest.db_secret, kubernetes_manifest.db_svc]
}

### Backend ─────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "backend_deployment" {
  manifest   = yamldecode(file("${local.kubernetes_path}/backend/backend-deployment.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.db_stateful_set]
}

resource "kubernetes_manifest" "backend_service" {
  manifest   = yamldecode(file("${local.kubernetes_path}/backend/backend-service.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.backend_deployment]
}

### Frontend ────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "frontend_deployment" {
  manifest   = yamldecode(file("${local.kubernetes_path}/frontend/frontend-deployment.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.backend_service]
}

resource "kubernetes_manifest" "frontend_service" {
  manifest   = yamldecode(file("${local.kubernetes_path}/frontend/frontend-service.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.frontend_deployment]
}

### Outputs ───────────────────────────────────────────────────────────────────
output "namespace" {
  description = "Namespace Kubernetes du déploiement Pixel War"
  value       = "pixelwar"
}

output "frontend_url" {
  description = "URL du frontend (port mappé automatiquement via Kind)"
  value       = "http://localhost:8080"
}

output "backend_url" {
  description = "URL du backend (port mappé automatiquement via Kind)"
  value       = "http://localhost:3000"
}
