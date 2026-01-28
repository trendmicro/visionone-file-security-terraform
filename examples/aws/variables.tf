variable "project_name" {
  description = "Project name to be used as a prefix for resources"
  type        = string
  default     = "v1fs"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication (e.g., 'dev', 'prod')"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_eks_cluster" {
  description = "Whether to create a new EKS cluster or use an existing one"
  type        = bool
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (existing or to be created)"
  type        = string
  default     = null
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster (only used if creating new cluster)"
  type        = string
  default     = "1.34"
}

variable "eks_cluster_endpoint_public_access" {
  description = "Enable public access to EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_private_access" {
  description = "Enable private access to EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "node_group_type" {
  description = "Node group capacity type: on-demand or spot"
  type        = string
  default     = "on-demand"
  validation {
    condition     = contains(["on-demand", "spot"], var.node_group_type)
    error_message = "Node group type must be either 'on-demand' or 'spot'."
  }
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 6
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.xlarge"]
}

variable "node_disk_size" {
  description = "Disk size in GB for EKS nodes"
  type        = number
  default     = 100
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster (must be in at least 2 AZs)"
  type        = list(string)
  default     = null
}

variable "subnet_type" {
  description = "Type of subnets: public or private"
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "private"], var.subnet_type)
    error_message = "Subnet type must be either 'public' or 'private'."
  }
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to EKS nodes"
  type        = list(string)
  default     = []
}

variable "create_alb_controller" {
  description = <<-EOT
    Whether to create AWS Load Balancer Controller resources.

    Set to true for:
    - New EKS clusters
    - Existing clusters without ALB Controller

    Set to false for:
    - Existing clusters that already have ALB Controller installed
  EOT
  type        = bool
  default     = true
}

variable "create_alb_controller_iam_role" {
  description = <<-EOT
    Whether to create IAM role for ALB Controller.

    Set to false if:
    - Deploying to existing cluster with IAM role already configured
    - You want to use an externally managed IAM role

    Only applicable when create_alb_controller = true.
  EOT
  type        = bool
  default     = true
}

variable "create_alb_controller_service_account" {
  description = <<-EOT
    Whether to create Kubernetes ServiceAccount for ALB Controller.

    Set to false if:
    - ServiceAccount already exists in the cluster
    - Using a pre-configured service account

    Only applicable when create_alb_controller = true.
  EOT
  type        = bool
  default     = true
}

variable "create_alb_controller_helm_release" {
  description = <<-EOT
    Whether to create Helm release for ALB Controller.

    Set to false if:
    - ALB Controller is already installed via Helm
    - You only need IAM role/ServiceAccount creation

    Only applicable when create_alb_controller = true.
  EOT
  type        = bool
  default     = true
}

variable "manage_network_cluster_tag" {
  description = <<-EOT
    Whether to manage kubernetes.io/cluster/<cluster_name> tag on subnets.

    Set to false if:
    - Subnets are shared with other EKS clusters
    - Tags are managed externally

    Only applicable when create_alb_controller = true.
  EOT
  type        = bool
  default     = true
}

variable "manage_network_elb_tag" {
  description = <<-EOT
    Whether to manage kubernetes.io/role/elb (or internal-elb) tag on subnets.

    WARNING: This tag is shared across all clusters using the same subnets.
    If you destroy this module with manage_network_elb_tag = true, the tag will be
    removed and may affect ALB Controller in other clusters.

    Set to false if:
    - Subnets are shared with other EKS clusters that use ALB Controller
    - Tags are already configured on the subnets
    - Tags are managed externally (e.g., by infrastructure team)

    Only applicable when create_alb_controller = true.
  EOT
  type        = bool
  default     = true
}

variable "alb_controller_version" {
  description = "Version of AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.8.1"
}

variable "alb_scheme" {
  description = "ALB scheme: internet-facing or internal"
  type        = string
  default     = "internet-facing"
  validation {
    condition     = contains(["internet-facing", "internal"], var.alb_scheme)
    error_message = "ALB scheme must be either 'internet-facing' or 'internal'."
  }
}

variable "certificate_arn" {
  description = <<-EOT
    ⚠️ REQUIRED: ACM certificate ARN for HTTPS/gRPC listeners.

    YOU MUST create and validate this certificate BEFORE deploying.

    Requirements:
    - Certificate MUST be in 'Issued' status (not pending validation)
    - Certificate MUST be in the SAME AWS region as your EKS cluster
    - Certificate MUST cover your v1fs_domain_name (exact match or wildcard)
    - DNS validation records MUST be already configured in your DNS provider

    Steps to create:
    1. Request certificate in AWS Certificate Manager (ACM)
    2. Add DNS validation records to your DNS provider (Route53, Cloudflare, etc.)
    3. Wait for certificate status to become 'Issued'
    4. Copy the certificate ARN

    Example ARN: arn:aws:acm:us-east-1:123456789012:certificate/abc-def-123

    To verify certificate status:
    aws acm describe-certificate --certificate-arn <your-arn> --region <region>
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.certificate_arn == "" || can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/[a-f0-9-]+$", var.certificate_arn))
    error_message = <<-EOT
      Invalid certificate ARN format.

      Expected: arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERT_ID
      Example: arn:aws:acm:us-east-1:123456789012:certificate/abc-def-123

      Common issues:
      - ARN is incomplete or truncated
      - Region in ARN doesn't match your deployment region
      - Wrong certificate type (must be ACM, not IAM server certificate)

      Note: Empty string is allowed for local deployments
    EOT
  }
}

variable "v1fs_domain_name" {
  description = <<-EOT
    ⚠️ REQUIRED: Fully qualified domain name (FQDN) for the scanner service.

    YOU MUST own this domain and configure DNS to point to the ALB AFTER deployment.

    This domain will be used for:
    - Scanner gRPC endpoint (e.g., https://scanner.example.com)
    - Management service endpoint (e.g., https://scanner.example.com/ontap)
    - ALB Ingress host configuration

    Requirements:
    - Must be a valid FQDN you own and control
    - Must be covered by your ACM certificate (exact match or wildcard)
    - You will need to create DNS records AFTER deployment (see outputs for ALB hostname)

    DNS Configuration (POST-DEPLOYMENT):
    After running terraform apply, you will receive the ALB hostname in outputs.
    You must create a DNS record in your DNS provider:
    - Type: CNAME or A (Alias if using Route53)
    - Name: your v1fs_domain_name
    - Value: ALB hostname from terraform outputs

    Examples:
    - scanner.example.com
    - v1fs.yourdomain.com
    - file-security.internal.company.com
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$", var.v1fs_domain_name))
    error_message = <<-EOT
      Invalid domain name format.

      Domain must:
      - Use only lowercase letters, numbers, dots, and hyphens
      - Not start or end with a hyphen
      - Be a valid FQDN

      Invalid: Scanner.Example.Com, -scanner.com, scanner-.com
      Valid: scanner.example.com, v1fs-prod.company.com
    EOT
  }
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
  description = "Port for ICAP service"
  type        = number
  default     = 1344
}

variable "nlb_scheme" {
  description = "NLB scheme for ICAP: internet-facing or internal"
  type        = string
  default     = "internet-facing"
  validation {
    condition     = contains(["internet-facing", "internal"], var.nlb_scheme)
    error_message = "NLB scheme must be either 'internet-facing' or 'internal'."
  }
}

variable "icap_certificate_arn" {
  description = "ACM certificate ARN for ICAP TLS (optional)"
  type        = string
  default     = ""
}

variable "v1fs_namespace" {
  description = "Kubernetes namespace for V1FS deployment"
  type        = string
  default     = "visionone-filesecurity"
}

variable "create_v1fs_namespace" {
  description = "Whether to create the V1FS namespace. Set to false if using an existing namespace like 'default' or if the namespace was created elsewhere"
  type        = bool
  default     = true
}

variable "v1fs_helm_chart_repository" {
  description = "Helm chart repository URL for Vision One File Security"
  type        = string
  default     = "https://trendmicro.github.io/visionone-file-security-helm/"
}

variable "v1fs_helm_chart_name" {
  description = "Name of the Vision One File Security Helm chart"
  type        = string
  default     = "visionone-filesecurity"
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
    The token is region-specific and determines which Vision One region
    your scanner connects to.

    How to obtain:
    1. Log in to Vision One console (https://portal.xdr.trendmicro.com/)
    2. Navigate to: File Security → Containerized Scanner
    3. Click "Add Scanner" or "Get Registration Token"
    4. Copy the token (starts with "eyJ...")

    Security note:
    - This is a sensitive credential
    - Do NOT commit to version control
    - Store in terraform.tfvars (which should be .gitignored)
    - Or use environment variable: TF_VAR_v1fs_registration_token

    Token format: JWT string starting with "eyJ0eXAiOiJKV1Qi..."
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$", var.v1fs_registration_token))
    error_message = <<-EOT
      Invalid registration token format.

      The token should be a JWT (JSON Web Token) that starts with "eyJ".

      Common issues:
      1. Token was truncated when copying - ensure you copy the complete token
      2. Extra spaces or line breaks were added - token should be a single line
      3. Wrong token type - make sure you copied the "registration token", not API key

      To get a valid token:
      1. Go to Vision One console → File Security → Containerized Scanner
      2. Click "Get Registration Token"
      3. Copy the entire token (it's very long, around 800-1000 characters)
    EOT
  }
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
  default     = 2
}

variable "enable_v1fs_scanner_autoscaling" {
  description = "Whether to enable autoscaling for scanner"
  type        = bool
  default     = false
}

variable "v1fs_scanner_autoscaling_min_replicas" {
  description = "Minimum replicas for scanner autoscaling"
  type        = number
  default     = 2
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

variable "manage_route53_records" {
  description = <<-EOT
    Whether to automatically create Route53 DNS records (OPTIONAL).

    This is a convenience feature for customers using Route53 as their DNS provider.

    Options:
    - false (default): You manage DNS records yourself (supports any DNS provider)
    - true: Terraform creates Route53 A (Alias) records for you

    Requirements when true:
    - You must provide route53_zone_id
    - Your domain must be managed by this Route53 hosted zone

    Use Cases:
    - Set to true: If you use Route53 and want convenience
    - Set to false: If you use other DNS providers (Cloudflare, GoDaddy, etc.)
                    or prefer manual DNS management

    Note: Even if false, you still need to create DNS records manually
          after deployment to point your domain to the ALB.
  EOT
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = <<-EOT
    Route53 hosted zone ID (OPTIONAL - only needed if manage_route53_records = true).

    This is the zone where your domain_name will be created.
    For example, if your domain_name is "scanner.example.com",
    you need the zone ID for "example.com".

    How to find your zone ID:
    1. AWS Console → Route53 → Hosted zones
    2. Click on your domain zone
    3. Copy the "Hosted zone ID" (e.g., Z0123456789ABC)

    Or use CLI:
    aws route53 list-hosted-zones --query "HostedZones[?Name=='example.com.'].Id" --output text

    Format: Alphanumeric string starting with Z (e.g., Z0123456789ABC)
    Note: Do NOT include the "/hostedzone/" prefix

    Leave empty if manage_route53_records = false
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.route53_zone_id == "" || can(regex("^Z[A-Z0-9]+$", var.route53_zone_id))
    error_message = <<-EOT
      Invalid Route53 zone ID format.

      Expected format: Z followed by alphanumeric characters (e.g., Z0123456789ABC)

      Common mistakes:
      1. Including "/hostedzone/" prefix - remove it
      2. Using zone name instead of ID - use the ID shown in Route53 console

      Correct: Z0123456789ABC
      Wrong: /hostedzone/Z0123456789ABC
      Wrong: example.com
    EOT
  }
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

variable "create_ebs_csi_driver" {
  description = <<-EOT
    Whether to create EBS CSI driver resources.

    Set to true for:
    - New EKS clusters
    - Existing clusters without EBS CSI driver
    - Clusters requiring database persistent storage

    Set to false for:
    - Existing clusters that already have EBS CSI driver installed
    - Clusters using alternative storage solutions

    The EBS CSI driver is required for:
    - EKS clusters version 1.23 and later
    - Dynamic provisioning of EBS volumes (gp2, gp3, io1, io2)
  EOT
  type        = bool
  default     = true
}

variable "create_ebs_csi_driver_iam_role" {
  description = <<-EOT
    Whether to create IAM role for EBS CSI Driver.

    Set to false if:
    - Deploying to existing cluster with IAM role already configured
    - You want to use an externally managed IAM role

    Only applicable when create_ebs_csi_driver = true.
  EOT
  type        = bool
  default     = true
}

variable "create_ebs_csi_driver_addon" {
  description = <<-EOT
    Whether to create EBS CSI Driver EKS addon.

    Set to false if:
    - EKS addon already exists but you want to create StorageClass
    - Using an externally managed EBS CSI driver

    Only applicable when create_ebs_csi_driver = true.
  EOT
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = <<-EOT
    Version of the EBS CSI driver add-on.

    Leave as null to use the latest compatible version for your EKS cluster.

    To find available versions:
    aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --kubernetes-version <version>

    Example versions: v1.28.0-eksbuild.1, v1.27.0-eksbuild.1
  EOT
  type        = string
  default     = null
}

variable "create_ebs_storage_class" {
  description = <<-EOT
    Whether to create StorageClass for EBS volumes.

    Set to true if:
    - You need a StorageClass for database persistent storage
    - Your cluster has EBS CSI driver installed (either by this module or pre-existing)

    Set to false if:
    - StorageClass already exists in the cluster
    - You want to use an existing StorageClass

    Note: This is independent of create_ebs_csi_driver. You can create a StorageClass
    even if you're not creating the EBS CSI driver (e.g., when the driver is pre-installed).
  EOT
  type        = bool
  default     = true
}

variable "ebs_volume_type" {
  description = <<-EOT
    EBS volume type for the database StorageClass.

    Available types:
    - gp3: General Purpose SSD (recommended) - baseline 3,000 IOPS, 125 MB/s
    - gp2: General Purpose SSD (older) - burstable IOPS
    - io1: Provisioned IOPS SSD - for high performance requirements
    - io2: Provisioned IOPS SSD - higher durability than io1
  EOT
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.ebs_volume_type)
    error_message = "ebs_volume_type must be one of: gp3, gp2, io1, io2."
  }
}

variable "set_storage_class_as_default" {
  description = "Whether to set the database StorageClass as the cluster default"
  type        = bool
  default     = false
}

variable "ebs_encrypted" {
  description = "Whether to encrypt EBS volumes by default (recommended for production)"
  type        = bool
  default     = true
}

variable "storage_class_reclaim_policy" {
  description = <<-EOT
    Reclaim policy for the database StorageClass.

    WARNING: 'Delete' will permanently remove EBS volumes when PVC is deleted!

    - Retain (default): EBS volume is retained for manual cleanup - RECOMMENDED for production
    - Delete: EBS volume is deleted when PVC is deleted - Use with caution

    For production databases, keep the default 'Retain' to prevent accidental data loss.
  EOT
  type        = string
  default     = "Retain"

  validation {
    condition     = contains(["Delete", "Retain"], var.storage_class_reclaim_policy)
    error_message = "storage_class_reclaim_policy must be 'Delete' or 'Retain'."
  }
}

variable "v1fs_database_persistence_size" {
  description = "Size of persistent volume for database (EBS)"
  type        = string
  default     = "100Gi"
}

variable "v1fs_database_storage_class_name" {
  description = "StorageClass name for database persistence"
  type        = string
  default     = "visionone-filesecurity-storage"
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
