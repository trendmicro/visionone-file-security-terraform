provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = merge(
      {
        Project   = var.project_name
        ManagedBy = "Terraform"
      },
      var.tags
    )
  }
}

data "aws_eks_cluster" "existing" {
  count = !var.create_eks_cluster ? 1 : 0
  name  = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  count = !var.create_eks_cluster ? 1 : 0
  name  = var.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "existing" {
  count = !var.create_eks_cluster ? 1 : 0
  url   = data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer
}

data "aws_subnet" "selected" {
  count = var.vpc_id == "" && length(var.subnet_ids) > 0 ? 1 : 0
  id    = var.subnet_ids[0]
}

locals {
  # VPC ID resolution: use explicit vpc_id if provided, otherwise derive from subnet
  vpc_id = var.vpc_id != "" ? var.vpc_id : (
    length(var.subnet_ids) > 0 ? data.aws_subnet.selected[0].vpc_id : null
  )

  cluster_endpoint = var.create_eks_cluster ? module.eks[0].cluster_endpoint : data.aws_eks_cluster.existing[0].endpoint

  cluster_certificate_authority_data = var.create_eks_cluster ? module.eks[0].cluster_certificate_authority_data : data.aws_eks_cluster.existing[0].certificate_authority[0].data

  cluster_name = var.create_eks_cluster ? module.eks[0].cluster_name : data.aws_eks_cluster.existing[0].name

  oidc_provider_arn = var.create_eks_cluster ? module.eks[0].oidc_provider_arn : data.aws_iam_openid_connect_provider.existing[0].arn

  oidc_provider_url = var.create_eks_cluster ? module.eks[0].oidc_provider_url : data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = concat(
      var.aws_profile != "" ? ["--profile", var.aws_profile] : [],
      [
        "eks",
        "get-token",
        "--cluster-name",
        local.cluster_name,
        "--region",
        var.aws_region
      ]
    )
  }
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = concat(
        var.aws_profile != "" ? ["--profile", var.aws_profile] : [],
        [
          "eks",
          "get-token",
          "--cluster-name",
          local.cluster_name,
          "--region",
          var.aws_region
        ]
      )
    }
  }
}

module "eks" {
  count  = var.create_eks_cluster ? 1 : 0
  source = "./modules/eks"

  cluster_name                    = var.eks_cluster_name
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_public_access  = var.eks_cluster_endpoint_public_access
  cluster_endpoint_private_access = var.eks_cluster_endpoint_private_access
  vpc_id                          = local.vpc_id
  subnet_ids                      = var.subnet_ids
  node_group_type                 = var.node_group_type
  node_group_min_size             = var.node_group_min_size
  node_group_max_size             = var.node_group_max_size
  node_group_desired_size         = var.node_group_desired_size
  node_instance_types             = var.node_instance_types
  node_disk_size                  = var.node_disk_size
  additional_security_group_ids   = var.additional_security_group_ids

  tags = var.tags
}

module "network" {
  count  = var.create_alb_controller ? 1 : 0
  source = "./modules/network"

  cluster_name = local.cluster_name
  subnet_ids   = var.subnet_ids
  subnet_type  = var.subnet_type

  manage_cluster_tag = var.manage_network_cluster_tag
  manage_elb_tag     = var.manage_network_elb_tag

  tags = var.tags
}

module "alb_controller" {
  count  = var.create_alb_controller ? 1 : 0
  source = "./modules/alb-controller"

  cluster_name                       = local.cluster_name
  cluster_endpoint                   = local.cluster_endpoint
  cluster_certificate_authority_data = local.cluster_certificate_authority_data

  create_iam_role   = var.create_alb_controller_iam_role
  oidc_provider_arn = local.oidc_provider_arn
  oidc_provider_url = local.oidc_provider_url

  chart_version        = var.alb_controller_version
  namespace            = "kube-system"
  service_account_name = "aws-load-balancer-controller"
  replica_count        = 2
  aws_region           = var.aws_region
  vpc_id               = local.vpc_id

  create_service_account = var.create_alb_controller_service_account
  create_helm_release    = var.create_alb_controller_helm_release

  tags = var.tags

  depends_on = [
    module.eks,
    module.network
  ]
}

module "ebs_csi_driver" {
  count  = var.create_ebs_csi_driver ? 1 : 0
  source = "./modules/ebs-csi-driver"

  cluster_name      = local.cluster_name
  oidc_provider_arn = local.oidc_provider_arn
  oidc_provider_url = local.oidc_provider_url

  create_iam_role = var.create_ebs_csi_driver_iam_role
  create_addon    = var.create_ebs_csi_driver_addon

  ebs_csi_driver_version = var.ebs_csi_driver_version

  tags = var.tags

  depends_on = [module.eks]
}

module "ebs_storage_class" {
  count  = var.create_ebs_storage_class ? 1 : 0
  source = "./modules/ebs-storage-class"

  storage_class_name = var.v1fs_database_storage_class_name
  volume_type        = var.ebs_volume_type
  set_as_default     = var.set_storage_class_as_default
  encrypted          = var.ebs_encrypted
  reclaim_policy     = var.storage_class_reclaim_policy

  depends_on = [module.ebs_csi_driver]
}

module "v1fs" {
  source = "../../modules/v1fs"

  namespace        = var.v1fs_namespace
  create_namespace = var.create_v1fs_namespace
  release_name     = var.project_name
  chart_version    = var.v1fs_helm_chart_version

  registration_token = var.v1fs_registration_token

  log_level          = var.v1fs_log_level
  enable_scan_cache  = var.enable_v1fs_scan_cache
  proxy_url          = var.v1fs_proxy_url
  management_plugins = var.v1fs_management_plugins

  scanner_replicas                 = var.v1fs_scanner_replicas
  enable_scanner_autoscaling       = var.enable_v1fs_scanner_autoscaling
  scanner_autoscaling_min_replicas = var.v1fs_scanner_autoscaling_min_replicas
  scanner_autoscaling_max_replicas = var.v1fs_scanner_autoscaling_max_replicas
  scanner_cpu_request              = var.v1fs_scanner_cpu_request
  scanner_memory_request           = var.v1fs_scanner_memory_request

  ingress_class_name  = "alb"
  domain_name         = var.v1fs_domain_name
  alb_certificate_arn = var.certificate_arn
  alb_scheme          = var.alb_scheme

  enable_management         = var.enable_v1fs_management
  management_cpu_request    = var.v1fs_management_cpu_request
  management_memory_request = var.v1fs_management_memory_request

  enable_icap          = var.enable_icap
  icap_port            = var.icap_port
  icap_nlb_scheme      = var.nlb_scheme
  icap_certificate_arn = var.icap_certificate_arn

  scan_cache_cpu_request    = var.v1fs_scan_cache_cpu_request
  scan_cache_memory_request = var.v1fs_scan_cache_memory_request

  backend_communicator_cpu_request    = var.v1fs_backend_communicator_cpu_request
  backend_communicator_memory_request = var.v1fs_backend_communicator_memory_request

  chart_path = var.v1fs_chart_path

  image_pull_secrets = var.v1fs_image_pull_secrets

  enable_management_db          = var.enable_v1fs_management_db
  database_persistence_size     = var.v1fs_database_persistence_size
  database_storage_class_name   = var.v1fs_database_storage_class_name
  create_database_storage_class = false

  depends_on = [
    module.alb_controller,
    module.ebs_csi_driver,
    module.ebs_storage_class
  ]
}

data "kubernetes_ingress_v1" "scanner" {
  count = 1

  metadata {
    name      = "${var.project_name}-visionone-filesecurity-scanner"
    namespace = module.v1fs.namespace
  }

  depends_on = [module.v1fs]
}

locals {
  # ALB Hosted Zone IDs by region
  # Reference: https://docs.aws.amazon.com/general/latest/gr/elb.html
  alb_zone_ids = {
    "us-east-1"      = "Z35SXDOTRQ7X7K"
    "us-east-2"      = "Z3AADJGX6KTTL2"
    "us-west-1"      = "Z368ELLRRE2KJ0"
    "us-west-2"      = "Z1H1FL5HABSF5"
    "ca-central-1"   = "ZQSVJUPU6J1EY"
    "eu-west-1"      = "Z32O12XQLNTSW2"
    "eu-central-1"   = "Z215JYRZR1TBD5"
    "eu-west-2"      = "ZHURV8PSTC4K8"
    "eu-west-3"      = "Z3Q77PNBQS71R4"
    "eu-north-1"     = "Z23TAZ6LKFMNIO"
    "ap-southeast-1" = "Z1LMS91P8CMLE5"
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"
    "ap-northeast-1" = "Z14GRHDCWA56QT"
    "ap-northeast-2" = "ZWKZPGTI48KDX"
    "ap-south-1"     = "ZP97RAFLXTNZK"
    "sa-east-1"      = "Z2P70J7HTTTPLU"
  }

  alb_zone_id     = lookup(local.alb_zone_ids, var.aws_region, null)
  scanner_alb_dns = try(data.kubernetes_ingress_v1.scanner[0].status[0].load_balancer[0].ingress[0].hostname, "")
}

resource "aws_route53_record" "scanner" {
  count = var.manage_route53_records && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.v1fs_domain_name
  type    = "A"

  alias {
    name                   = local.scanner_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = true
  }

  lifecycle {
    precondition {
      condition     = local.alb_zone_id != null
      error_message = <<-EOT
        Unsupported AWS region '${var.aws_region}' for ALB.

        The ALB hosted zone ID for this region is not configured.

        Supported regions:
        us-east-1, us-east-2, us-west-1, us-west-2, ca-central-1,
        eu-west-1, eu-central-1, eu-west-2, eu-west-3, eu-north-1,
        ap-southeast-1, ap-southeast-2, ap-northeast-1, ap-northeast-2,
        ap-south-1, sa-east-1

        To add support for a new region, update the alb_zone_ids map in main.tf.
        Reference: https://docs.aws.amazon.com/general/latest/gr/elb.html
      EOT
    }

    precondition {
      condition     = local.scanner_alb_dns != ""
      error_message = <<-EOT
        Scanner ALB hostname is not available yet.

        This usually means the ALB Controller has not finished provisioning the ALB.

        Troubleshooting steps:
        1. Wait 2-3 minutes and run 'terraform apply' again
        2. Check ingress status: kubectl get ingress -n ${module.v1fs.namespace}
        3. Check ALB Controller logs: kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50
        4. Verify ALB Controller is running: kubectl get pods -n kube-system | grep aws-load-balancer

        Common causes:
        - ALB Controller not installed or not running
        - Missing IAM permissions for ALB Controller
        - Subnet tags missing for ALB discovery
        - Certificate ARN invalid or not in 'Issued' status
      EOT
    }

    precondition {
      condition     = var.route53_zone_id != ""
      error_message = "route53_zone_id must be provided when manage_route53_records = true"
    }
  }

  depends_on = [
    data.kubernetes_ingress_v1.scanner,
    module.v1fs
  ]
}
