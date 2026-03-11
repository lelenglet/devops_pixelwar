# Provider configuration
provider "kubernetes" {
  config_path = "${path.module}/.kube/config"
}

# Create a Kubernetes deployment
resource "kubernetes_deployment_v1" "example_deployment" {
  metadata {
    name = "example-deployment"
    labels = {
      app = "example-app"
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "example-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "example-app"
        }
      }
      spec {
        container {
          name = "example-container"
          image = "your-image:latest"
        }
      }
    }
  }
}
# Create a Kubernetes service
resource "kubernetes_service_v1" "example_service" {
  metadata {
    name = "example-service"
  }
  spec {
    selector = {
      app = "example-app"
    }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}