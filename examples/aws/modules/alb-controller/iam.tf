data "http" "alb_controller_iam_policy" {
  count = var.create_iam_role ? 1 : 0
  url   = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  count = var.create_iam_role ? 1 : 0

  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_controller_iam_policy[0].response_body

  tags = var.tags
}

resource "aws_iam_policy" "alb_set_rule_priorities" {
  count = var.create_iam_role ? 1 : 0

  name        = "${var.cluster_name}-ALBSetRulePriorities"
  description = "Additional IAM policy to allow setting ALB rule priorities"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:SetRulePriorities"]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

locals {
  oidc_provider_id = replace(var.oidc_provider_url, "https://", "")
}

data "aws_iam_policy_document" "alb_controller_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.cluster_name}-AWSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.alb_controller[0].name
  policy_arn = aws_iam_policy.alb_controller[0].arn
}

resource "aws_iam_role_policy_attachment" "alb_set_rule_priorities" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.alb_controller[0].name
  policy_arn = aws_iam_policy.alb_set_rule_priorities[0].arn
}
