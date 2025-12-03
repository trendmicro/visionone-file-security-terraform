variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster. Required when create_iam_role is true."
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster. Required when create_iam_role is true."
  type        = string
  default     = ""
}

variable "create_iam_role" {
  description = "Whether to create IAM role for EBS CSI Driver. Set to false if using an existing cluster with IAM role already configured."
  type        = bool
  default     = true
}

variable "create_addon" {
  description = "Whether to create the EBS CSI driver as an EKS add-on"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "Version of the EBS CSI driver add-on. Use 'aws eks describe-addon-versions --addon-name aws-ebs-csi-driver' to find available versions."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
