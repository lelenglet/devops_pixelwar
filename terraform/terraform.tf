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
