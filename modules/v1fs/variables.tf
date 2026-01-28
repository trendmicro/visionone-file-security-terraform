variable "namespace" {
  description = "Kubernetes namespace for V1FS deployment"
  type        = string
  default     = "visionone-filesecurity"
}

variable "create_namespace" {
  description = "Whether to create the namespace. Set to false if the namespace already exists (e.g., using 'default' or pre-existing namespace)"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
}

variable "chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://trendmicro.github.io/visionone-file-security-helm/"
}

variable "chart_path" {
  description = <<-EOT
    Local path to Helm chart directory. When set, chart_repository and chart_version are ignored.
    Use this for development or on-premise deployments with local charts.
    Path is relative to the Terraform root module (where you call this module).
    Example: "../../../v1fs-helm/amaas-helm/visionone-filesecurity"
  EOT
  type        = string
  default     = null
}

variable "chart_name" {
  description = "Helm chart name when using remote repository. Ignored when chart_path is set."
  type        = string
  default     = "visionone-filesecurity"
}

variable "chart_version" {
  description = "Helm chart version. Required when using remote repository (chart_path is null)."
  type        = string
  default     = null
}

variable "registration_token" {
  description = "Vision One registration token"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$", var.registration_token))
    error_message = "Registration token must be a valid JWT token starting with 'eyJ'."
  }
}

variable "log_level" {
  description = "Log level for V1FS services"
  type        = string
  default     = "INFO"
}

variable "enable_scan_cache" {
  description = "Enable scan result caching"
  type        = bool
  default     = true
}

variable "proxy_url" {
  description = "HTTP/HTTPS proxy URL"
  type        = string
  default     = ""
}

variable "no_proxy" {
  description = "Comma-separated no_proxy list for all V1FS components"
  type        = string
  default     = "localhost,127.0.0.1,.svc.cluster.local"
}

variable "scanner_config_map_name" {
  description = "ConfigMap name for scanner configuration"
  type        = string
  default     = "scanner-config"
}

variable "management_websocket_prefix" {
  description = "WebSocket path prefix for the management service"
  type        = string
  default     = "/ontap"

  validation {
    condition     = can(regex("^/", var.management_websocket_prefix))
    error_message = "Management websocket prefix must start with '/'."
  }
}

variable "management_plugins" {
  description = <<-EOT
    Management service plugins configuration.
    Each plugin requires ALL fields to be specified.

    Required fields for ontap-agent:
      - name               (required) - Plugin identifier (e.g., "ontap-agent")
      - enabled            (required) - Whether the plugin is enabled
      - configMapName      (required) - Name of the ConfigMap for plugin configuration
      - securitySecretName (required) - Name of the Secret for security credentials
      - jwtSecretName      (required) - Name of the Secret for JWT token

    Example (ontap-agent):
      management_plugins = [
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

variable "scanner_replicas" {
  description = "Number of scanner replicas"
  type        = number
  default     = 1
}

variable "enable_scanner_autoscaling" {
  description = "Whether to enable autoscaling for scanner"
  type        = bool
  default     = false
}

variable "scanner_autoscaling_min_replicas" {
  description = "Minimum replicas for scanner autoscaling"
  type        = number
  default     = 1
}

variable "scanner_autoscaling_max_replicas" {
  description = "Maximum replicas for scanner autoscaling"
  type        = number
  default     = 10
}

variable "scanner_cpu_request" {
  description = "CPU request for scanner pods"
  type        = string
  default     = "800m"
}

variable "scanner_memory_request" {
  description = "Memory request for scanner pods"
  type        = string
  default     = "2Gi"
}

variable "domain_name" {
  description = "Domain name for ingress"
  type        = string
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (required for AWS ALB, optional for other ingress controllers)"
  type        = string
  default     = ""
}

variable "alb_scheme" {
  description = "ALB scheme: internet-facing or internal"
  type        = string
  default     = "internet-facing"

  validation {
    condition     = contains(["internet-facing", "internal"], var.alb_scheme)
    error_message = "alb_scheme must be 'internet-facing' or 'internal'."
  }
}

variable "enable_management" {
  description = "Whether to enable management service"
  type        = bool
  default     = false
}

variable "management_cpu_request" {
  description = "CPU request for management service pods"
  type        = string
  default     = "250m"
}

variable "management_memory_request" {
  description = "Memory request for management service pods"
  type        = string
  default     = "256Mi"
}

variable "enable_icap" {
  description = <<-EOT
    [NOT PRODUCTION READY] Enable ICAP service with NLB.

    ⚠️ WARNING: ICAP feature is NOT READY for production use!
    Currently, only gRPC protocol is supported and stable.
    ICAP support is under development and should remain disabled.

    Use gRPC protocol instead for production deployments.
  EOT
  type        = bool
  default     = false
}

variable "icap_port" {
  description = "ICAP service port"
  type        = number
  default     = 1344
}

variable "icap_nlb_scheme" {
  description = "NLB scheme for ICAP: internet-facing or internal"
  type        = string
  default     = "internet-facing"

  validation {
    condition     = contains(["internet-facing", "internal"], var.icap_nlb_scheme)
    error_message = "icap_nlb_scheme must be 'internet-facing' or 'internal'."
  }
}

variable "icap_certificate_arn" {
  description = "ACM certificate ARN for ICAP TLS (optional)"
  type        = string
  default     = ""
}

variable "scan_cache_cpu_request" {
  description = "CPU request for scan cache pods"
  type        = string
  default     = "250m"
}

variable "scan_cache_memory_request" {
  description = "Memory request for scan cache pods"
  type        = string
  default     = "512Mi"
}

variable "backend_communicator_cpu_request" {
  description = "CPU request for backend communicator pods"
  type        = string
  default     = "250m"
}

variable "backend_communicator_memory_request" {
  description = "Memory request for backend communicator pods"
  type        = string
  default     = "128Mi"
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., 'alb', 'nginx', 'gce')"
  type        = string
  default     = "alb"

  validation {
    condition     = contains(["alb", "nginx"], var.ingress_class_name)
    error_message = "ingress_class_name must be 'alb' or 'nginx'."
  }
}

variable "scanner_extra_ingress_annotations" {
  description = "Additional annotations for scanner ingress (merged with defaults)"
  type        = map(string)
  default     = {}
}

variable "management_extra_ingress_annotations" {
  description = "Additional annotations for management ingress (merged with defaults)"
  type        = map(string)
  default     = {}
}

variable "enable_management_db" {
  description = "Whether to enable PostgreSQL database container for management service. Requires enable_management = true."
  type        = bool
  default     = false
}

variable "database_cpu_request" {
  description = "CPU request for database container pods"
  type        = string
  default     = "250m"
}

variable "database_cpu_limit" {
  description = "CPU limit for database container pods"
  type        = string
  default     = "500m"
}

variable "database_memory_request" {
  description = "Memory request for database container pods"
  type        = string
  default     = "512Mi"
}

variable "database_memory_limit" {
  description = "Memory limit for database container pods"
  type        = string
  default     = "1Gi"
}

variable "database_persistence_size" {
  description = "Size of persistent volume for database (e.g., '10Gi', '100Gi')"
  type        = string
  default     = "100Gi"
}

variable "create_database_storage_class" {
  description = "Whether to create a StorageClass for database persistence. Set to false when using cloud provider storage classes (e.g., EBS gp3)."
  type        = bool
  default     = true
}

variable "database_storage_class_name" {
  description = "StorageClass name for database persistence. Use 'gp3' or 'gp2' for AWS EBS, or custom name for local/hostPath."
  type        = string
  default     = "visionone-filesecurity-storage"
}

variable "database_storage_class_host_path" {
  description = "Host path for local StorageClass (only used when database_storage_class_create = true)"
  type        = string
  default     = "/mnt/data/postgres"
}

variable "database_storage_class_reclaim_policy" {
  description = "Reclaim policy for the StorageClass: Delete or Retain"
  type        = string
  default     = "Retain"

  validation {
    condition     = contains(["Delete", "Retain"], var.database_storage_class_reclaim_policy)
    error_message = "database_storage_class_reclaim_policy must be 'Delete' or 'Retain'."
  }
}

variable "enable_telemetry_prometheus" {
  description = "Whether to enable Prometheus agent for metrics collection and forwarding to Vision One"
  type        = bool
  default     = true
}

variable "prometheus_cpu_request" {
  description = "CPU request for Prometheus agent pods"
  type        = string
  default     = "100m"
}

variable "prometheus_cpu_limit" {
  description = "CPU limit for Prometheus agent pods"
  type        = string
  default     = "200m"
}

variable "prometheus_memory_request" {
  description = "Memory request for Prometheus agent pods"
  type        = string
  default     = "128Mi"
}

variable "prometheus_memory_limit" {
  description = "Memory limit for Prometheus agent pods"
  type        = string
  default     = "256Mi"
}

variable "prometheus_scrape_interval" {
  description = "Prometheus scrape interval (e.g., '60s', '30s')"
  type        = string
  default     = "60s"
}

variable "prometheus_log_level" {
  description = "Log level for Prometheus agent (debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "prometheus_init_cpu_request" {
  description = "CPU request for Prometheus init container"
  type        = string
  default     = "50m"
}

variable "prometheus_init_cpu_limit" {
  description = "CPU limit for Prometheus init container"
  type        = string
  default     = "100m"
}

variable "prometheus_init_memory_request" {
  description = "Memory request for Prometheus init container"
  type        = string
  default     = "64Mi"
}

variable "prometheus_init_memory_limit" {
  description = "Memory limit for Prometheus init container"
  type        = string
  default     = "128Mi"
}

variable "enable_telemetry_kube_state_metrics" {
  description = "Whether to enable kube-state-metrics for Kubernetes resource metrics"
  type        = bool
  default     = true
}

variable "kube_state_metrics_cpu_request" {
  description = "CPU request for kube-state-metrics pods"
  type        = string
  default     = "50m"
}

variable "kube_state_metrics_cpu_limit" {
  description = "CPU limit for kube-state-metrics pods"
  type        = string
  default     = "100m"
}

variable "kube_state_metrics_memory_request" {
  description = "Memory request for kube-state-metrics pods"
  type        = string
  default     = "64Mi"
}

variable "kube_state_metrics_memory_limit" {
  description = "Memory limit for kube-state-metrics pods"
  type        = string
  default     = "128Mi"
}

variable "extra_helm_values" {
  description = <<-EOT
    Additional Helm values as a list of YAML strings. Applied after module defaults.
    Later entries override earlier ones using Helm's deep merge strategy.
    Useful for injecting values from files or complex configurations not covered by module variables.

    Example:
      extra_helm_values = [
        file("custom-values.yaml"),
        yamlencode({
          scanner = {
            nodeSelector = { "node-type" = "scanner" }
            tolerations = [{
              key    = "dedicated"
              value  = "scanner"
              effect = "NoSchedule"
            }]
          }
        })
      ]
  EOT
  type        = list(string)
  default     = []
}

variable "image_pull_secrets" {
  description = <<-EOT
    List of Kubernetes secret names for pulling images from private registries.
    Applied globally to all V1FS components (scanner, scanCache, backendCommunicator, managementService, databaseContainer).

    Example: image_pull_secrets = ["my-registry-secret"]
  EOT
  type        = list(string)
  default     = []
}
