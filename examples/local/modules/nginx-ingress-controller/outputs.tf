output "namespace" {
  description = "Namespace where NGINX Ingress Controller is deployed"
  value       = var.create_helm_release ? helm_release.nginx_ingress[0].namespace : null
}

output "chart_version" {
  description = "Version of NGINX Ingress Controller Helm chart"
  value       = var.create_helm_release ? helm_release.nginx_ingress[0].version : null
}

output "release_name" {
  description = "Name of the Helm release"
  value       = var.create_helm_release ? helm_release.nginx_ingress[0].name : null
}

output "service_type" {
  description = "Service type of the ingress controller"
  value       = var.create_helm_release ? data.kubernetes_service.nginx_ingress[0].spec[0].type : null
}
