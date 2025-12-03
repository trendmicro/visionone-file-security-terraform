output "iam_role_arn" {
  description = "ARN of the IAM role for EBS CSI driver"
  value       = var.create_iam_role ? aws_iam_role.ebs_csi[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for EBS CSI driver"
  value       = var.create_iam_role ? aws_iam_role.ebs_csi[0].name : null
}

output "ebs_csi_driver_addon_id" {
  description = "ID of the EBS CSI driver EKS add-on"
  value       = var.create_addon ? aws_eks_addon.ebs_csi[0].id : null
}

output "ebs_csi_driver_addon_version" {
  description = "Version of the EBS CSI driver EKS add-on"
  value       = var.create_addon ? aws_eks_addon.ebs_csi[0].addon_version : null
}
