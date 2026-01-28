variable "project_name" {
  description = "Project name to be used as a prefix for resources"
  type        = string
  default     = "v1fs"
}

variable "create_nginx_ingress_controller" {
  description = "Whether to create NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "nginx_ingress_controller_version" {
  description = "Version of NGINX Ingress Controller Helm chart"
  type        = string
  default     = "4.14.0"
}

variable "nginx_service_type" {
  description = "Service type for NGINX Ingress Controller (NodePort for local, LoadBalancer for cloud)"
  type        = string
  default     = "NodePort"
}

variable "v1fs_namespace" {
  description = "Kubernetes namespace for V1FS deployment"
  type        = string
  default     = "visionone-filesecurity"
}

variable "create_v1fs_namespace" {
  description = "Whether to create the V1FS namespace"
  type        = bool
  default     = true
}

variable "v1fs_helm_chart_version" {
  description = "Version of Vision One File Security Helm chart"
  type        = string
  default     = "1.4.2"
}

variable "v1fs_registration_token" {
  description = <<-EOT
    Vision One File Security registration token for scanner authentication.

    This JWT token authenticates your scanner with Vision One cloud service.

    How to obtain:
    1. Log in to Vision One console (https://portal.xdr.trendmicro.com/)
    2. Navigate to: File Security → Containerized Scanner
    3. Click "Add Scanner" or "Get Registration Token"
    4. Copy the token (starts with "eyJ...")

    Token format: JWT string starting with "eyJ0eXAiOiJKV1Qi..."
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$", var.v1fs_registration_token))
    error_message = "Registration token must be a valid JWT token starting with 'eyJ'."
  }
}

variable "v1fs_domain_name" {
  description = "Domain name for the scanner service (e.g., scanner.local.k8s)"
  type        = string
  default     = "scanner.local.k8s"
}

variable "v1fs_log_level" {
  description = "Log level for V1FS services (DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.v1fs_log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}

variable "enable_v1fs_scan_cache" {
  description = "Whether to enable scan result caching with Redis/Valkey"
  type        = bool
  default     = true
}

variable "v1fs_proxy_url" {
  description = "HTTP/HTTPS proxy URL for V1FS services (optional)"
  type        = string
  default     = ""
}

variable "v1fs_scanner_replicas" {
  description = "Number of scanner replicas"
  type        = number
  default     = 1
}

variable "enable_v1fs_scanner_autoscaling" {
  description = "Whether to enable autoscaling for scanner"
  type        = bool
  default     = false
}

variable "v1fs_scanner_autoscaling_min_replicas" {
  description = "Minimum replicas for scanner autoscaling"
  type        = number
  default     = 1
}

variable "v1fs_scanner_autoscaling_max_replicas" {
  description = "Maximum replicas for scanner autoscaling"
  type        = number
  default     = 10
}

variable "v1fs_scanner_cpu_request" {
  description = "CPU request for scanner pods"
  type        = string
  default     = "800m"
}

variable "v1fs_scanner_memory_request" {
  description = "Memory request for scanner pods"
  type        = string
  default     = "2Gi"
}

variable "enable_v1fs_management" {
  description = "Whether to enable management service"
  type        = bool
  default     = true
}

variable "v1fs_management_cpu_request" {
  description = "CPU request for management service pods"
  type        = string
  default     = "250m"
}

variable "v1fs_management_memory_request" {
  description = "Memory request for management service pods"
  type        = string
  default     = "256Mi"
}

variable "v1fs_management_plugins" {
  description = <<-EOT
    List of plugins to enable for management service.
    Each plugin requires ALL fields to be specified.

    Required fields for ontap-agent:
      - name               (required) - Plugin identifier (e.g., "ontap-agent")
      - enabled            (required) - Whether the plugin is enabled
      - configMapName      (required) - Name of the ConfigMap for plugin configuration
      - securitySecretName (required) - Name of the Secret for security credentials
      - jwtSecretName      (required) - Name of the Secret for JWT token

    Example (ontap-agent):
      v1fs_management_plugins = [
        {
          name               = "ontap-agent"
          enabled            = true
          configMapName      = "ontap-agent-config"
          securitySecretName = "ontap-agent-security"
          jwtSecretName      = "ontap-agent-jwt"
        }
      ]
  EOT
  type        = list(map(any))
  default     = []
}

variable "v1fs_scan_cache_cpu_request" {
  description = "CPU request for scan cache pods"
  type        = string
  default     = "250m"
}

variable "v1fs_scan_cache_memory_request" {
  description = "Memory request for scan cache pods"
  type        = string
  default     = "512Mi"
}

variable "v1fs_backend_communicator_cpu_request" {
  description = "CPU request for backend communicator pods"
  type        = string
  default     = "250m"
}

variable "v1fs_backend_communicator_memory_request" {
  description = "Memory request for backend communicator pods"
  type        = string
  default     = "128Mi"
}

variable "v1fs_chart_path" {
  description = "Local path to helm chart (relative to this example directory). Set to use local chart for development."
  type        = string
  default     = null
}

variable "v1fs_image_pull_secrets" {
  description = "List of Kubernetes secret names for pulling images from private registries"
  type        = list(string)
  default     = []
}

variable "enable_v1fs_management_db" {
  description = "Whether to enable PostgreSQL database for management service"
  type        = bool
  default     = false
}

variable "v1fs_database_persistence_size" {
  description = "Size of persistent volume for database"
  type        = string
  default     = "10Gi"
}

variable "v1fs_database_storage_class_host_path" {
  description = "Host path for local StorageClass"
  type        = string
  default     = "/mnt/data/postgres"
}

variable "v1fs_database_cpu_request" {
  description = "CPU request for database container pods"
  type        = string
  default     = "250m"
}

variable "v1fs_database_cpu_limit" {
  description = "CPU limit for database container pods"
  type        = string
  default     = "500m"
}

variable "v1fs_database_memory_request" {
  description = "Memory request for database container pods"
  type        = string
  default     = "512Mi"
}

variable "v1fs_database_memory_limit" {
  description = "Memory limit for database container pods"
  type        = string
  default     = "1Gi"
}

variable "enable_v1fs_telemetry_prometheus" {
  description = "Whether to enable Prometheus agent for metrics collection and forwarding to Vision One"
  type        = bool
  default     = true
}

variable "v1fs_prometheus_cpu_request" {
  description = "CPU request for Prometheus agent pods"
  type        = string
  default     = "100m"
}

variable "v1fs_prometheus_cpu_limit" {
  description = "CPU limit for Prometheus agent pods"
  type        = string
  default     = "200m"
}

variable "v1fs_prometheus_memory_request" {
  description = "Memory request for Prometheus agent pods"
  type        = string
  default     = "128Mi"
}

variable "v1fs_prometheus_memory_limit" {
  description = "Memory limit for Prometheus agent pods"
  type        = string
  default     = "256Mi"
}

variable "v1fs_prometheus_scrape_interval" {
  description = "Prometheus scrape interval (e.g., '60s', '30s')"
  type        = string
  default     = "60s"
}

variable "v1fs_prometheus_log_level" {
  description = "Log level for Prometheus agent (debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "enable_v1fs_telemetry_kube_state_metrics" {
  description = "Whether to enable kube-state-metrics for Kubernetes resource metrics"
  type        = bool
  default     = true
}

variable "v1fs_kube_state_metrics_cpu_request" {
  description = "CPU request for kube-state-metrics pods"
  type        = string
  default     = "50m"
}

variable "v1fs_kube_state_metrics_cpu_limit" {
  description = "CPU limit for kube-state-metrics pods"
  type        = string
  default     = "100m"
}

variable "v1fs_kube_state_metrics_memory_request" {
  description = "Memory request for kube-state-metrics pods"
  type        = string
  default     = "64Mi"
}

variable "v1fs_kube_state_metrics_memory_limit" {
  description = "Memory limit for kube-state-metrics pods"
  type        = string
  default     = "128Mi"
}
