variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.34"
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to cluster endpoint"
  type        = bool
  default     = true
}

variable "node_group_type" {
  description = "Node group capacity type: on-demand or spot"
  type        = string
  default     = "on-demand"
}

variable "node_group_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 6
}

variable "node_group_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "Instance types for node group"
  type        = list(string)
  default     = ["t3.xlarge"]
}

variable "node_disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 100
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to nodes"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
