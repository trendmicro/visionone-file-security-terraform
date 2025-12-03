# ----------------------------------------------------------------------------
# IAM Outputs
# ----------------------------------------------------------------------------

output "iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = var.create_iam_role ? aws_iam_role.alb_controller[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for AWS Load Balancer Controller"
  value       = var.create_iam_role ? aws_iam_role.alb_controller[0].name : null
}

output "iam_policy_arn" {
  description = "ARN of the main IAM policy for AWS Load Balancer Controller"
  value       = var.create_iam_role ? aws_iam_policy.alb_controller[0].arn : null
}

# ----------------------------------------------------------------------------
# Kubernetes Outputs
# ----------------------------------------------------------------------------

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = var.create_service_account ? kubernetes_service_account.alb_controller[0].metadata[0].name : null
}

output "namespace" {
  description = "Namespace where the controller is installed"
  value       = var.create_helm_release ? helm_release.alb_controller[0].namespace : null
}

output "chart_version" {
  description = "Version of the Helm chart deployed"
  value       = var.create_helm_release ? helm_release.alb_controller[0].version : null
}

output "release_name" {
  description = "Name of the Helm release"
  value       = var.create_helm_release ? helm_release.alb_controller[0].name : null
}
