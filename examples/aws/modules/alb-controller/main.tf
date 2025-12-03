# ============================================================================
# AWS Load Balancer Controller Module
# ============================================================================
# This module deploys the AWS Load Balancer Controller to an EKS cluster.
# It manages IAM roles, Kubernetes service accounts, and the Helm release.

locals {
  # Use the IAM role created by this module, or empty string if not created
  service_account_role_arn = var.create_iam_role ? aws_iam_role.alb_controller[0].arn : ""
}

# ----------------------------------------------------------------------------
# Kubernetes Service Account
# ----------------------------------------------------------------------------
# Creates a service account with IRSA annotation to allow the controller
# to assume the IAM role for AWS API access.

resource "kubernetes_service_account" "alb_controller" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = local.service_account_role_arn
    }
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }

  depends_on = [
    aws_iam_role.alb_controller
  ]
}

# ----------------------------------------------------------------------------
# Helm Release
# ----------------------------------------------------------------------------
# Deploys the AWS Load Balancer Controller using the official Helm chart.

locals {
  alb_controller_values = {
    clusterName  = var.cluster_name
    region       = var.aws_region
    vpcId        = var.vpc_id
    replicaCount = var.replica_count

    serviceAccount = {
      create = false
      name   = var.service_account_name
    }
  }
}

resource "helm_release" "alb_controller" {
  count = var.create_helm_release ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  namespace  = var.namespace

  values = [yamlencode(local.alb_controller_values)]

  depends_on = [
    kubernetes_service_account.alb_controller
  ]
}
