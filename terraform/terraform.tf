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
  host = var.host
  config_path    = var.kube_config_path
  config_context = var.kube_config_context

  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

locals {
  kubernetes_path = "${path.module}/../kubernetes"
  # Applique le namespace "default" aux manifests qui n'en ont pas
  with_namespace = { for k, v in {
    db_secret       = file("${local.kubernetes_path}/db/db-secret.yaml")
    db_svc          = file("${local.kubernetes_path}/db/db-svc.yaml")
    db_stateful_set = file("${local.kubernetes_path}/db/db-stateful-set.yaml")
  } : k => merge(
    yamldecode(v),
    { metadata = merge(lookup(yamldecode(v), "metadata", {}), { namespace = "default" }) }
  ) }
}

### Manifests Kubernetes (dossier kubernetes/) ────────────────────────────────
resource "kubernetes_manifest" "namespace" {
  manifest = yamldecode(file("${local.kubernetes_path}/namespace.yaml"))
}

resource "kubernetes_manifest" "db_secret" {
  manifest   = local.with_namespace["db_secret"]
  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "db_svc" {
  manifest   = local.with_namespace["db_svc"]
  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "db_stateful_set" {
  manifest   = local.with_namespace["db_stateful_set"]
  depends_on = [kubernetes_manifest.db_secret, kubernetes_manifest.db_svc]
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


### Variables ────────────────────────────────────────────────────────────
variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
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
