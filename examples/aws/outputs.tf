output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = local.cluster_endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = var.create_eks_cluster ? module.eks[0].cluster_version : data.aws_eks_cluster.existing[0].version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.create_eks_cluster ? module.eks[0].cluster_security_group_id : data.aws_eks_cluster.existing[0].vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = local.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID where EKS is deployed"
  value       = local.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs used by EKS"
  value       = var.create_eks_cluster ? module.eks[0].subnet_ids : data.aws_eks_cluster.existing[0].vpc_config[0].subnet_ids
}

output "subnet_type" {
  description = "Type of subnets - public or private"
  value       = var.subnet_type
}

output "alb_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = length(module.alb_controller) > 0 ? module.alb_controller[0].iam_role_arn : null
}

output "alb_controller_policy_arn" {
  description = "ARN of IAM policy for AWS Load Balancer Controller"
  value       = length(module.alb_controller) > 0 ? module.alb_controller[0].iam_policy_arn : null
}

output "alb_controller_installed" {
  description = "Whether AWS Load Balancer Controller is installed"
  value       = length(module.alb_controller) > 0 && module.alb_controller[0].release_name != null
}

output "alb_controller_version" {
  description = "Version of AWS Load Balancer Controller"
  value       = var.create_alb_controller ? module.alb_controller[0].chart_version : null
}

output "v1fs_namespace" {
  description = "Kubernetes namespace for Vision One File Security"
  value       = module.v1fs.namespace
}

output "v1fs_release_name" {
  description = "Name of the V1FS Helm release"
  value       = module.v1fs.release_name
}

output "v1fs_release_version" {
  description = "Version of the deployed V1FS Helm release"
  value       = module.v1fs.release_version
}

output "v1fs_chart_version" {
  description = "Version of the deployed V1FS Helm chart"
  value       = module.v1fs.chart_version
}

output "scanner_endpoint" {
  description = "Scanner service endpoint URL"
  value       = module.v1fs.scanner_endpoint
}

output "scanner_domain" {
  description = "Scanner service domain name"
  value       = var.manage_route53_records && length(aws_route53_record.scanner) > 0 ? aws_route53_record.scanner[0].name : var.v1fs_domain_name
}

output "management_service_enabled" {
  description = "Whether management service is enabled"
  value       = module.v1fs.management_enabled
}

output "management_service_endpoint" {
  description = "Management service endpoint URL"
  value       = module.v1fs.management_endpoint
}

output "icap_enabled" {
  description = "Whether ICAP service is enabled"
  value       = module.v1fs.icap_enabled
}

output "icap_port" {
  description = "ICAP service port"
  value       = var.enable_icap ? var.icap_port : null
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = var.aws_profile != "" ? "aws --profile ${var.aws_profile} eks update-kubeconfig --name ${local.cluster_name} --region ${var.aws_region}" : "aws eks update-kubeconfig --name ${local.cluster_name} --region ${var.aws_region}"
}

output "get_ingress_info" {
  description = "Command to get ingress information"
  value       = "kubectl get ingress -n ${module.v1fs.namespace}"
}

output "get_nlb_dns" {
  description = "Command to get NLB DNS name for ICAP"
  value       = var.enable_icap ? "kubectl get service -n ${module.v1fs.namespace} -o jsonpath='{.items[?(@.spec.type==\"LoadBalancer\")].status.loadBalancer.ingress[0].hostname}'" : null
}

output "scanner_alb_hostname" {
  description = "ALB hostname for scanner service - USE THIS to create your DNS records"
  value       = length(data.kubernetes_ingress_v1.scanner) > 0 ? try(data.kubernetes_ingress_v1.scanner[0].status[0].load_balancer[0].ingress[0].hostname, "") : null
}

output "scanner_alb_zone_id" {
  description = "ALB hosted zone ID for Route53 Alias records"
  value       = local.alb_zone_id
}

output "route53_managed" {
  description = "Whether Route53 DNS records are managed by Terraform"
  value       = var.manage_route53_records
}

output "route53_record_created" {
  description = "Whether Route53 record was successfully created"
  value       = var.manage_route53_records && length(aws_route53_record.scanner) > 0
}

output "scanner_dns_fqdn" {
  description = "Fully qualified domain name for scanner"
  value       = var.manage_route53_records && length(aws_route53_record.scanner) > 0 ? aws_route53_record.scanner[0].fqdn : var.v1fs_domain_name
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                        DEPLOYMENT COMPLETE!                              ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    ┌──────────────────────────────────────────────────────────────────────────┐
    │ 1. VERIFY DEPLOYMENT                                                     │
    └──────────────────────────────────────────────────────────────────────────┘

    Configure kubectl:
    ${var.aws_profile != "" ? format("aws --profile %s eks update-kubeconfig --name %s --region %s", var.aws_profile, local.cluster_name, var.aws_region) : format("aws eks update-kubeconfig --name %s --region %s", local.cluster_name, var.aws_region)}

    Check pods are running:
    kubectl get pods -n ${module.v1fs.namespace}

    Get ALB hostname:
    kubectl get ingress -n ${module.v1fs.namespace}

    ┌──────────────────────────────────────────────────────────────────────────┐
    │ 2. TEST DNS RESOLUTION                                                   │
    └──────────────────────────────────────────────────────────────────────────┘

    Wait 2-5 minutes for DNS propagation, then test:
    nslookup ${var.v1fs_domain_name}

    For detailed outputs, run: terraform output
  EOT
}
