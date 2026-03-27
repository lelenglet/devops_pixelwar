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

  wait    = true
  timeout = var.helm_timeout_seconds
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
