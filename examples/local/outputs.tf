# ============================================================================
# V1FS Outputs
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where V1FS is deployed"
  value       = module.v1fs.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = module.v1fs.release_name
}

output "scanner_endpoint" {
  description = "Scanner service endpoint"
  value       = module.v1fs.scanner_endpoint
}

output "management_enabled" {
  description = "Whether management service is enabled"
  value       = module.v1fs.management_enabled
}

output "management_endpoint" {
  description = "Management service endpoint (if enabled)"
  value       = module.v1fs.management_endpoint
}

# ============================================================================
# Access Instructions
# ============================================================================

output "access_instructions" {
  description = "Instructions to access the scanner service"
  value       = <<-EOT

    ========================================
    Vision One File Security - Local Deployment
    ========================================

    Scanner Endpoint: ${module.v1fs.scanner_endpoint}
    Namespace: ${module.v1fs.namespace}

    To access the scanner service locally:

    1. Add to /etc/hosts:
       127.0.0.1 ${var.v1fs_domain_name}

    2. Get NGINX Ingress NodePort:
       kubectl get svc -n ingress-nginx ingress-nginx-controller

    3. Access via:
       http://${var.v1fs_domain_name}:<NodePort>

    4. Check scanner status:
       kubectl get pods -n ${module.v1fs.namespace}
       kubectl logs -n ${module.v1fs.namespace} -l app=scanner

    ${var.enable_v1fs_management ? "Management Endpoint: ${module.v1fs.management_endpoint}" : ""}

  EOT
}
