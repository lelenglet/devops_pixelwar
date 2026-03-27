variable "kube_config_path" {
  description = "Chemin vers le fichier kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_config_context" {
  description = "Context Kubernetes à utiliser (ex: kind-pixel-war)"
  type        = string
  default     = "kind-pixel-war"
}

variable "helm_release_name" {
  description = "Nom du release Helm (doit correspondre aux préfixes des services du chart)"
  type        = string
  default     = "pixelwar"
}

variable "helm_namespace" {
  description = "Namespace Kubernetes cible (aligné sur values.yaml du chart)"
  type        = string
  default     = "pixelwar"
}

variable "helm_timeout_seconds" {
  description = "Timeout Helm wait (secondes), équivalent à --timeout de helm (ex. 900 = 15m)"
  type        = number
  default     = 900
}
