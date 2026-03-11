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
  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "frontend_service" {
  manifest   = yamldecode(file("${local.kubernetes_path}/frontend/frontend-service.yml"))
  depends_on = [kubernetes_manifest.namespace, kubernetes_manifest.frontend_deployment]
}

### Utilisateur user ────────────────────────────────────────────────────────────
resource "kubernetes_secret" "demo_auth" {
  metadata {
    name      = "demo-auth"
    namespace = "default"
  }

  data = {
    username = "user"
    password = "dino"
  }
}




### Ressources ────────────────────────────────────────────────────────────
resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "nginx:stable-alpine-slim"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}


### Load balancer ────────────────────────────────────────────────────────────
resource "kubernetes_service_v1" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      App = kubernetes_deployment_v1.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}
