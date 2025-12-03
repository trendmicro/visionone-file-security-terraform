variable "namespace" {
  description = "Kubernetes namespace for NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "Version of NGINX Ingress Controller Helm chart"
  type        = string
  default     = "4.14.0"
}

variable "create_helm_release" {
  description = "Whether to create the Helm release"
  type        = bool
  default     = true
}

variable "service_type" {
  description = "Service type for ingress controller (NodePort for local, LoadBalancer for cloud)"
  type        = string
  default     = "NodePort"

  validation {
    condition     = contains(["NodePort", "LoadBalancer"], var.service_type)
    error_message = "service_type must be 'NodePort' or 'LoadBalancer'."
  }
}

variable "replica_count" {
  description = "Number of replicas for NGINX Ingress Controller"
  type        = number
  default     = 1
}

variable "cpu_request" {
  description = "CPU request for NGINX Ingress Controller pods"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for NGINX Ingress Controller pods"
  type        = string
  default     = "90Mi"
}

variable "enable_admission_webhooks" {
  description = "Enable admission webhooks (can be disabled for local development)"
  type        = bool
  default     = false
}
