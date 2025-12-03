variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  type        = string
}

variable "create_iam_role" {
  description = "Whether to create IAM role for ALB Controller. Set to false if using an existing cluster with IAM role already configured."
  type        = bool
  default     = true
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

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}

variable "chart_version" {
  description = "Version of the aws-load-balancer-controller Helm chart"
  type        = string
  default     = "1.14.1"
}

variable "namespace" {
  description = "Kubernetes namespace to install the controller"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "replica_count" {
  description = "Number of replicas for the controller"
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "create_service_account" {
  description = "Whether to create the Kubernetes service account. Set to false if it already exists in the cluster."
  type        = bool
  default     = true
}

variable "create_helm_release" {
  description = "Whether to create the Helm release. Set to false if the ALB Controller is already installed."
  type        = bool
  default     = true
}
