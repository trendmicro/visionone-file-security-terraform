variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to tag for load balancers"
  type        = list(string)
}

variable "subnet_type" {
  description = "Type of subnets: public or private"
  type        = string
  validation {
    condition     = contains(["public", "private"], var.subnet_type)
    error_message = "Subnet type must be either 'public' or 'private'."
  }
}

variable "manage_cluster_tag" {
  description = <<-EOT
    Whether to manage kubernetes.io/cluster/<cluster_name> tag on subnets.

    Set to false if:
    - Subnets are shared with other EKS clusters
    - Tags are managed externally
  EOT
  type        = bool
  default     = true
}

variable "manage_elb_tag" {
  description = <<-EOT
    Whether to manage kubernetes.io/role/elb (or internal-elb) tag on subnets.

    WARNING: This tag is shared across all clusters using the same subnets.
    If you destroy this module, the tag will be removed and may affect
    ALB Controller in other clusters.

    Set to false if:
    - Subnets are shared with other EKS clusters that use ALB Controller
    - Tags are already configured on the subnets
    - Tags are managed externally (e.g., by infrastructure team)
  EOT
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to subnets"
  type        = map(string)
  default     = {}
}
