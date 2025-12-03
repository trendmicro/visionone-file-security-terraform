output "namespace" {
  description = "Kubernetes namespace name"
  value       = var.create_namespace ? kubernetes_namespace.v1fs[0].metadata[0].name : var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.v1fs.name
}

output "release_version" {
  description = "Deployed Helm release version"
  value       = helm_release.v1fs.version
}

output "chart_version" {
  description = "Helm chart version"
  value       = helm_release.v1fs.chart
}

output "token_secret_name" {
  description = "Name of the token secret"
  value       = kubernetes_secret.token.metadata[0].name
}

output "device_token_secret_name" {
  description = "Name of the device token secret"
  value       = kubernetes_secret.device_token.metadata[0].name
}

output "scanner_endpoint" {
  description = "Scanner service endpoint"
  value       = "https://${var.domain_name}"
}

output "management_enabled" {
  description = "Whether management service is enabled"
  value       = var.enable_management
}

output "management_endpoint" {
  description = "Management service endpoint"
  value       = var.enable_management ? "https://${var.domain_name}${var.management_websocket_prefix}" : null
}

output "icap_enabled" {
  description = "Whether ICAP service is enabled"
  value       = var.enable_icap
}

output "chart_source" {
  description = "Helm chart source (local path or repository URL)"
  value       = local.use_local_chart ? var.chart_path : "${var.chart_repository}/${var.chart_name}"
}

output "is_local_chart" {
  description = "Whether using local Helm chart"
  value       = local.use_local_chart
}

output "database_enabled" {
  description = "Whether PostgreSQL database is enabled for management service"
  value       = var.enable_management_db
}
