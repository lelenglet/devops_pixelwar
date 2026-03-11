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
