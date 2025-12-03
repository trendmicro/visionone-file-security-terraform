# AWS EKS Example for Vision One File Security

This example deploys [Trend Micro Vision One File Security](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-file-security-containerized-scanner) on AWS EKS with full infrastructure automation.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                              VPC                                      │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                        EKS Cluster                              │  │  │
│  │  │                                                                 │  │  │
│  │  │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │  │  │
│  │  │   │   Scanner   │    │  Scan Cache │    │  Backend    │         │  │  │
│  │  │   │   (gRPC)    │    │  (Valkey)   │    │Communicator │         │  │  │
│  │  │   └─────────────┘    └─────────────┘    └─────────────┘         │  │  │
│  │  │          ▲                                                      │  │  │
│  │  │          │           ┌─────────────┐    ┌─────────────┐         │  │  │
│  │  │          │           │ Management  │───▶│  Database   │         │  │  │
│  │  │          │           │  Service    │    │ (PostgreSQL)│         │  │  │
│  │  │          │           └─────────────┘    └──────┬──────┘         │  │  │
│  │  │          │                  ▲                  │                │  │  │
│  │  │   ┌─────────────┐           │           ┌──────▼──────┐         │  │  │
│  │  │   │   Ingress   │───────────┘           │EBS CSI      │         │  │  │
│  │  │   │   (ALB)     │                       │Driver       │         │  │  │
│  │  │   └─────────────┘                       └──────┬──────┘         │  │  │
│  │  │          ▲                                     │                │  │  │
│  │  │          │        ┌─────────────────┐          │                │  │  │
│  │  │          │        │  ALB Controller │          │                │  │  │
│  │  │          │◄───────│  (manages ALB)  │          │                │  │  │
│  │  │          │        └─────────────────┘          │                │  │  │
│  │  └──────────│─────────────────────────────────────│────────────────┘  │  │
│  │             │                                     │                   │  │
│  │   ┌─────────────────┐                      ┌──────▼──────┐            │  │
│  │   │ Application     │                      │ EBS Volume  │            │  │
│  │   │ Load Balancer   │◄─ ACM Certificate    │ (Persistent)│            │  │
│  │   └─────────────────┘                      └─────────────┘            │  │
│  │             ▲                                                         │  │
│  └─────────────│─────────────────────────────────────────────────────────┘  │
│                │                                                            │
│   ┌────────────────────┐                                                    │
│   │     Route53        │  (Optional: auto-managed DNS records)              │
│   │   Hosted Zone      │                                                    │
│   └────────────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                 ▲
                 │ HTTPS/gRPC
                 │
         ┌───────────────┐
         │    Clients    │
         │  (Your Apps)  │
         └───────────────┘
```

## Prerequisites

### Required AWS Resources (Must Create Before Deployment)

| Resource | Description | How to Create |
|----------|-------------|---------------|
| **ACM Certificate** | TLS certificate for HTTPS/gRPC | AWS Console → Certificate Manager → Request certificate |
| **Route53 Hosted Zone** | DNS zone for your domain (if using Route53) | AWS Console → Route53 → Create hosted zone |
| **VPC & Subnets** | Network infrastructure with at least 2 AZs | Use existing or create new VPC |

> **⚠️ Important:** The ACM certificate **MUST** be in `Issued` status before deployment. DNS validation records must be configured and verified.

### Certificate Requirements

1. **Same Region**: Certificate must be in the same AWS region as your EKS cluster
2. **Domain Coverage**: Certificate must cover your `v1fs_domain_name` (exact match or wildcard)
3. **Issued Status**: Certificate must be fully validated and in `Issued` status

```bash
# Verify certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/xxx \
  --query 'Certificate.Status'
# Expected output: "ISSUED"
```

### Vision One Registration Token

1. Log in to [Vision One Console](https://portal.xdr.trendmicro.com/)
2. Navigate to: **File Security** → **Containerized Scanner**
3. Click **Add Scanner** or **Get Registration Token**
4. Copy the token (starts with `eyJ...`)

### Software Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS CLI | >= 2.0 |
| kubectl | >= 1.24 |
| Helm | >= 3.0 |

## Quick Start

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:

```hcl
# Required
aws_region              = "us-east-1"
create_eks_cluster      = true
eks_cluster_name        = "visionone-filesecurity"
v1fs_domain_name        = "scanner.example.com"
v1fs_registration_token = "eyJ..."  # Your Vision One token
certificate_arn         = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"

# Network
subnet_ids = ["subnet-xxx", "subnet-yyy"]  # At least 2 AZs

# Optional: Auto-manage Route53 DNS records
manage_route53_records = true
route53_zone_id        = "Z0123456789ABC"
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --name visionone-filesecurity --region us-east-1
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n visionone-filesecurity

# Get ALB hostname
kubectl get ingress -n visionone-filesecurity
```

## Using an Existing EKS Cluster

If you already have an EKS cluster, set `create_eks_cluster = false`:

```hcl
create_eks_cluster = false
eks_cluster_name   = "my-existing-cluster"

# Network settings for your existing cluster
vpc_id     = "vpc-xxx"
subnet_ids = ["subnet-xxx", "subnet-yyy"]
```

### Existing ALB Ingress Controller

If your cluster already has AWS Load Balancer Controller installed:

```hcl
create_alb_controller = false
```

If you need to install ALB Controller but your subnets are shared with other clusters:

```hcl
create_alb_controller      = true
manage_network_elb_tag     = false  # Don't manage shared elb tags
manage_network_cluster_tag = true   # Cluster-specific tag is safe
```

### Existing EBS CSI Driver

If your cluster already has EBS CSI Driver installed:

```hcl
create_ebs_csi_driver          = false
create_ebs_csi_driver_iam_role = false
create_ebs_csi_driver_addon    = false

# Still create StorageClass if needed
create_ebs_storage_class = true
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.11 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_controller"></a> [alb\_controller](#module\_alb\_controller) | ./modules/alb-controller | n/a |
| <a name="module_ebs_csi_driver"></a> [ebs\_csi\_driver](#module\_ebs\_csi\_driver) | ./modules/ebs-csi-driver | n/a |
| <a name="module_ebs_storage_class"></a> [ebs\_storage\_class](#module\_ebs\_storage\_class) | ./modules/ebs-storage-class | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |
| <a name="module_v1fs"></a> [v1fs](#module\_v1fs) | ../../modules/v1fs | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.scanner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_eks_cluster.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_openid_connect_provider.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [kubernetes_ingress_v1.scanner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/ingress_v1) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Additional security group IDs to attach to EKS nodes | `list(string)` | `[]` | no |
| <a name="input_alb_controller_version"></a> [alb\_controller\_version](#input\_alb\_controller\_version) | Version of AWS Load Balancer Controller Helm chart | `string` | `"1.8.1"` | no |
| <a name="input_alb_scheme"></a> [alb\_scheme](#input\_alb\_scheme) | ALB scheme: internet-facing or internal | `string` | `"internet-facing"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS CLI profile to use for authentication (e.g., 'dev', 'prod') | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ⚠️ REQUIRED: ACM certificate ARN for HTTPS/gRPC listeners.<br/><br/>YOU MUST create and validate this certificate BEFORE deploying.<br/><br/>Requirements:<br/>- Certificate MUST be in 'Issued' status (not pending validation)<br/>- Certificate MUST be in the SAME AWS region as your EKS cluster<br/>- Certificate MUST cover your v1fs\_domain\_name (exact match or wildcard)<br/>- DNS validation records MUST be already configured in your DNS provider<br/><br/>Steps to create:<br/>1. Request certificate in AWS Certificate Manager (ACM)<br/>2. Add DNS validation records to your DNS provider (Route53, Cloudflare, etc.)<br/>3. Wait for certificate status to become 'Issued'<br/>4. Copy the certificate ARN<br/><br/>Example ARN: arn:aws:acm:us-east-1:123456789012:certificate/abc-def-123<br/><br/>To verify certificate status:<br/>aws acm describe-certificate --certificate-arn <your-arn> --region <region> | `string` | `""` | no |
| <a name="input_create_alb_controller"></a> [create\_alb\_controller](#input\_create\_alb\_controller) | Whether to create AWS Load Balancer Controller resources.<br/><br/>Set to true for:<br/>- New EKS clusters<br/>- Existing clusters without ALB Controller<br/><br/>Set to false for:<br/>- Existing clusters that already have ALB Controller installed | `bool` | `true` | no |
| <a name="input_create_alb_controller_helm_release"></a> [create\_alb\_controller\_helm\_release](#input\_create\_alb\_controller\_helm\_release) | Whether to create Helm release for ALB Controller.<br/><br/>Set to false if:<br/>- ALB Controller is already installed via Helm<br/>- You only need IAM role/ServiceAccount creation<br/><br/>Only applicable when create\_alb\_controller = true. | `bool` | `true` | no |
| <a name="input_create_alb_controller_iam_role"></a> [create\_alb\_controller\_iam\_role](#input\_create\_alb\_controller\_iam\_role) | Whether to create IAM role for ALB Controller.<br/><br/>Set to false if:<br/>- Deploying to existing cluster with IAM role already configured<br/>- You want to use an externally managed IAM role<br/><br/>Only applicable when create\_alb\_controller = true. | `bool` | `true` | no |
| <a name="input_create_alb_controller_service_account"></a> [create\_alb\_controller\_service\_account](#input\_create\_alb\_controller\_service\_account) | Whether to create Kubernetes ServiceAccount for ALB Controller.<br/><br/>Set to false if:<br/>- ServiceAccount already exists in the cluster<br/>- Using a pre-configured service account<br/><br/>Only applicable when create\_alb\_controller = true. | `bool` | `true` | no |
| <a name="input_create_ebs_csi_driver"></a> [create\_ebs\_csi\_driver](#input\_create\_ebs\_csi\_driver) | Whether to create EBS CSI driver resources.<br/><br/>Set to true for:<br/>- New EKS clusters<br/>- Existing clusters without EBS CSI driver<br/>- Clusters requiring database persistent storage<br/><br/>Set to false for:<br/>- Existing clusters that already have EBS CSI driver installed<br/>- Clusters using alternative storage solutions<br/><br/>The EBS CSI driver is required for:<br/>- EKS clusters version 1.23 and later<br/>- Dynamic provisioning of EBS volumes (gp2, gp3, io1, io2) | `bool` | `true` | no |
| <a name="input_create_ebs_csi_driver_addon"></a> [create\_ebs\_csi\_driver\_addon](#input\_create\_ebs\_csi\_driver\_addon) | Whether to create EBS CSI Driver EKS addon.<br/><br/>Set to false if:<br/>- EKS addon already exists but you want to create StorageClass<br/>- Using an externally managed EBS CSI driver<br/><br/>Only applicable when create\_ebs\_csi\_driver = true. | `bool` | `true` | no |
| <a name="input_create_ebs_csi_driver_iam_role"></a> [create\_ebs\_csi\_driver\_iam\_role](#input\_create\_ebs\_csi\_driver\_iam\_role) | Whether to create IAM role for EBS CSI Driver.<br/><br/>Set to false if:<br/>- Deploying to existing cluster with IAM role already configured<br/>- You want to use an externally managed IAM role<br/><br/>Only applicable when create\_ebs\_csi\_driver = true. | `bool` | `true` | no |
| <a name="input_create_ebs_storage_class"></a> [create\_ebs\_storage\_class](#input\_create\_ebs\_storage\_class) | Whether to create StorageClass for EBS volumes.<br/><br/>Set to true if:<br/>- You need a StorageClass for database persistent storage<br/>- Your cluster has EBS CSI driver installed (either by this module or pre-existing)<br/><br/>Set to false if:<br/>- StorageClass already exists in the cluster<br/>- You want to use an existing StorageClass<br/><br/>Note: This is independent of create\_ebs\_csi\_driver. You can create a StorageClass<br/>even if you're not creating the EBS CSI driver (e.g., when the driver is pre-installed). | `bool` | `true` | no |
| <a name="input_create_eks_cluster"></a> [create\_eks\_cluster](#input\_create\_eks\_cluster) | Whether to create a new EKS cluster or use an existing one | `bool` | n/a | yes |
| <a name="input_create_v1fs_namespace"></a> [create\_v1fs\_namespace](#input\_create\_v1fs\_namespace) | Whether to create the V1FS namespace. Set to false if using an existing namespace like 'default' or if the namespace was created elsewhere | `bool` | `true` | no |
| <a name="input_ebs_csi_driver_version"></a> [ebs\_csi\_driver\_version](#input\_ebs\_csi\_driver\_version) | Version of the EBS CSI driver add-on.<br/><br/>Leave as null to use the latest compatible version for your EKS cluster.<br/><br/>To find available versions:<br/>aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --kubernetes-version <version><br/><br/>Example versions: v1.28.0-eksbuild.1, v1.27.0-eksbuild.1 | `string` | `null` | no |
| <a name="input_ebs_encrypted"></a> [ebs\_encrypted](#input\_ebs\_encrypted) | Whether to encrypt EBS volumes by default (recommended for production) | `bool` | `true` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | EBS volume type for the database StorageClass.<br/><br/>Available types:<br/>- gp3: General Purpose SSD (recommended) - baseline 3,000 IOPS, 125 MB/s<br/>- gp2: General Purpose SSD (older) - burstable IOPS<br/>- io1: Provisioned IOPS SSD - for high performance requirements<br/>- io2: Provisioned IOPS SSD - higher durability than io1 | `string` | `"gp3"` | no |
| <a name="input_eks_cluster_endpoint_private_access"></a> [eks\_cluster\_endpoint\_private\_access](#input\_eks\_cluster\_endpoint\_private\_access) | Enable private access to EKS cluster endpoint | `bool` | `true` | no |
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Enable public access to EKS cluster endpoint | `bool` | `true` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster (existing or to be created) | `string` | `null` | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | Kubernetes version for EKS cluster (only used if creating new cluster) | `string` | `"1.34"` | no |
| <a name="input_enable_icap"></a> [enable\_icap](#input\_enable\_icap) | [NOT PRODUCTION READY] Enable ICAP service with NLB.<br/><br/>⚠️ WARNING: ICAP feature is NOT READY for production use!<br/>Currently, only gRPC protocol is supported and stable.<br/>ICAP support is under development and should remain disabled.<br/><br/>Use gRPC protocol instead for production deployments. | `bool` | `false` | no |
| <a name="input_enable_v1fs_management"></a> [enable\_v1fs\_management](#input\_enable\_v1fs\_management) | Whether to enable management service | `bool` | `true` | no |
| <a name="input_enable_v1fs_management_db"></a> [enable\_v1fs\_management\_db](#input\_enable\_v1fs\_management\_db) | Whether to enable PostgreSQL database for management service | `bool` | `false` | no |
| <a name="input_enable_v1fs_scan_cache"></a> [enable\_v1fs\_scan\_cache](#input\_enable\_v1fs\_scan\_cache) | Whether to enable scan result caching with Redis/Valkey | `bool` | `true` | no |
| <a name="input_enable_v1fs_scanner_autoscaling"></a> [enable\_v1fs\_scanner\_autoscaling](#input\_enable\_v1fs\_scanner\_autoscaling) | Whether to enable autoscaling for scanner | `bool` | `false` | no |
| <a name="input_icap_certificate_arn"></a> [icap\_certificate\_arn](#input\_icap\_certificate\_arn) | ACM certificate ARN for ICAP TLS (optional) | `string` | `""` | no |
| <a name="input_icap_port"></a> [icap\_port](#input\_icap\_port) | Port for ICAP service | `number` | `1344` | no |
| <a name="input_manage_network_cluster_tag"></a> [manage\_network\_cluster\_tag](#input\_manage\_network\_cluster\_tag) | Whether to manage kubernetes.io/cluster/<cluster\_name> tag on subnets.<br/><br/>Set to false if:<br/>- Subnets are shared with other EKS clusters<br/>- Tags are managed externally<br/><br/>Only applicable when create\_alb\_controller = true. | `bool` | `true` | no |
| <a name="input_manage_network_elb_tag"></a> [manage\_network\_elb\_tag](#input\_manage\_network\_elb\_tag) | Whether to manage kubernetes.io/role/elb (or internal-elb) tag on subnets.<br/><br/>WARNING: This tag is shared across all clusters using the same subnets.<br/>If you destroy this module with manage\_network\_elb\_tag = true, the tag will be<br/>removed and may affect ALB Controller in other clusters.<br/><br/>Set to false if:<br/>- Subnets are shared with other EKS clusters that use ALB Controller<br/>- Tags are already configured on the subnets<br/>- Tags are managed externally (e.g., by infrastructure team)<br/><br/>Only applicable when create\_alb\_controller = true. | `bool` | `true` | no |
| <a name="input_manage_route53_records"></a> [manage\_route53\_records](#input\_manage\_route53\_records) | Whether to automatically create Route53 DNS records (OPTIONAL).<br/><br/>This is a convenience feature for customers using Route53 as their DNS provider.<br/><br/>Options:<br/>- false (default): You manage DNS records yourself (supports any DNS provider)<br/>- true: Terraform creates Route53 A (Alias) records for you<br/><br/>Requirements when true:<br/>- You must provide route53\_zone\_id<br/>- Your domain must be managed by this Route53 hosted zone<br/><br/>Use Cases:<br/>- Set to true: If you use Route53 and want convenience<br/>- Set to false: If you use other DNS providers (Cloudflare, GoDaddy, etc.)<br/>                or prefer manual DNS management<br/><br/>Note: Even if false, you still need to create DNS records manually<br/>      after deployment to point your domain to the ALB. | `bool` | `false` | no |
| <a name="input_nlb_scheme"></a> [nlb\_scheme](#input\_nlb\_scheme) | NLB scheme for ICAP: internet-facing or internal | `string` | `"internet-facing"` | no |
| <a name="input_node_disk_size"></a> [node\_disk\_size](#input\_node\_disk\_size) | Disk size in GB for EKS nodes | `number` | `100` | no |
| <a name="input_node_group_desired_size"></a> [node\_group\_desired\_size](#input\_node\_group\_desired\_size) | Desired number of nodes in the node group | `number` | `2` | no |
| <a name="input_node_group_max_size"></a> [node\_group\_max\_size](#input\_node\_group\_max\_size) | Maximum number of nodes in the node group | `number` | `6` | no |
| <a name="input_node_group_min_size"></a> [node\_group\_min\_size](#input\_node\_group\_min\_size) | Minimum number of nodes in the node group | `number` | `2` | no |
| <a name="input_node_group_type"></a> [node\_group\_type](#input\_node\_group\_type) | Node group capacity type: on-demand or spot | `string` | `"on-demand"` | no |
| <a name="input_node_instance_types"></a> [node\_instance\_types](#input\_node\_instance\_types) | Instance types for EKS node group | `list(string)` | <pre>[<br/>  "t3.xlarge"<br/>]</pre> | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name to be used as a prefix for resources | `string` | `"v1fs"` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route53 hosted zone ID (OPTIONAL - only needed if manage\_route53\_records = true).<br/><br/>This is the zone where your domain\_name will be created.<br/>For example, if your domain\_name is "scanner.example.com",<br/>you need the zone ID for "example.com".<br/><br/>How to find your zone ID:<br/>1. AWS Console → Route53 → Hosted zones<br/>2. Click on your domain zone<br/>3. Copy the "Hosted zone ID" (e.g., Z0123456789ABC)<br/><br/>Or use CLI:<br/>aws route53 list-hosted-zones --query "HostedZones[?Name=='example.com.'].Id" --output text<br/><br/>Format: Alphanumeric string starting with Z (e.g., Z0123456789ABC)<br/>Note: Do NOT include the "/hostedzone/" prefix<br/><br/>Leave empty if manage\_route53\_records = false | `string` | `""` | no |
| <a name="input_set_storage_class_as_default"></a> [set\_storage\_class\_as\_default](#input\_set\_storage\_class\_as\_default) | Whether to set the database StorageClass as the cluster default | `bool` | `false` | no |
| <a name="input_storage_class_reclaim_policy"></a> [storage\_class\_reclaim\_policy](#input\_storage\_class\_reclaim\_policy) | Reclaim policy for the database StorageClass.<br/><br/>WARNING: 'Delete' will permanently remove EBS volumes when PVC is deleted!<br/><br/>- Retain (default): EBS volume is retained for manual cleanup - RECOMMENDED for production<br/>- Delete: EBS volume is deleted when PVC is deleted - Use with caution<br/><br/>For production databases, keep the default 'Retain' to prevent accidental data loss. | `string` | `"Retain"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for EKS cluster (must be in at least 2 AZs) | `list(string)` | `null` | no |
| <a name="input_subnet_type"></a> [subnet\_type](#input\_subnet\_type) | Type of subnets: public or private | `string` | `"public"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_v1fs_backend_communicator_cpu_request"></a> [v1fs\_backend\_communicator\_cpu\_request](#input\_v1fs\_backend\_communicator\_cpu\_request) | CPU request for backend communicator pods | `string` | `"250m"` | no |
| <a name="input_v1fs_backend_communicator_memory_request"></a> [v1fs\_backend\_communicator\_memory\_request](#input\_v1fs\_backend\_communicator\_memory\_request) | Memory request for backend communicator pods | `string` | `"128Mi"` | no |
| <a name="input_v1fs_chart_path"></a> [v1fs\_chart\_path](#input\_v1fs\_chart\_path) | Local path to helm chart (relative to this example directory). Set to use local chart for development. | `string` | `null` | no |
| <a name="input_v1fs_database_persistence_size"></a> [v1fs\_database\_persistence\_size](#input\_v1fs\_database\_persistence\_size) | Size of persistent volume for database (EBS) | `string` | `"100Gi"` | no |
| <a name="input_v1fs_database_storage_class_name"></a> [v1fs\_database\_storage\_class\_name](#input\_v1fs\_database\_storage\_class\_name) | StorageClass name for database persistence | `string` | `"visionone-filesecurity-storage"` | no |
| <a name="input_v1fs_domain_name"></a> [v1fs\_domain\_name](#input\_v1fs\_domain\_name) | ⚠️ REQUIRED: Fully qualified domain name (FQDN) for the scanner service.<br/><br/>YOU MUST own this domain and configure DNS to point to the ALB AFTER deployment.<br/><br/>This domain will be used for:<br/>- Scanner gRPC endpoint (e.g., https://scanner.example.com)<br/>- Management service endpoint (e.g., https://scanner.example.com/ontap)<br/>- ALB Ingress host configuration<br/><br/>Requirements:<br/>- Must be a valid FQDN you own and control<br/>- Must be covered by your ACM certificate (exact match or wildcard)<br/>- You will need to create DNS records AFTER deployment (see outputs for ALB hostname)<br/><br/>DNS Configuration (POST-DEPLOYMENT):<br/>After running terraform apply, you will receive the ALB hostname in outputs.<br/>You must create a DNS record in your DNS provider:<br/>- Type: CNAME or A (Alias if using Route53)<br/>- Name: your v1fs\_domain\_name<br/>- Value: ALB hostname from terraform outputs<br/><br/>Examples:<br/>- scanner.example.com<br/>- v1fs.yourdomain.com<br/>- file-security.internal.company.com | `string` | n/a | yes |
| <a name="input_v1fs_helm_chart_name"></a> [v1fs\_helm\_chart\_name](#input\_v1fs\_helm\_chart\_name) | Name of the Vision One File Security Helm chart | `string` | `"visionone-filesecurity"` | no |
| <a name="input_v1fs_helm_chart_repository"></a> [v1fs\_helm\_chart\_repository](#input\_v1fs\_helm\_chart\_repository) | Helm chart repository URL for Vision One File Security | `string` | `"https://trendmicro.github.io/visionone-file-security-helm/"` | no |
| <a name="input_v1fs_helm_chart_version"></a> [v1fs\_helm\_chart\_version](#input\_v1fs\_helm\_chart\_version) | Version of Vision One File Security Helm chart | `string` | `"1.4.0"` | no |
| <a name="input_v1fs_image_pull_secrets"></a> [v1fs\_image\_pull\_secrets](#input\_v1fs\_image\_pull\_secrets) | List of Kubernetes secret names for pulling images from private registries | `list(string)` | `[]` | no |
| <a name="input_v1fs_log_level"></a> [v1fs\_log\_level](#input\_v1fs\_log\_level) | Log level for V1FS services (DEBUG, INFO, WARN, ERROR) | `string` | `"INFO"` | no |
| <a name="input_v1fs_management_cpu_request"></a> [v1fs\_management\_cpu\_request](#input\_v1fs\_management\_cpu\_request) | CPU request for management service pods | `string` | `"250m"` | no |
| <a name="input_v1fs_management_memory_request"></a> [v1fs\_management\_memory\_request](#input\_v1fs\_management\_memory\_request) | Memory request for management service pods | `string` | `"256Mi"` | no |
| <a name="input_v1fs_management_plugins"></a> [v1fs\_management\_plugins](#input\_v1fs\_management\_plugins) | List of plugins to enable for management service.<br/>Each plugin is a map with plugin-specific fields.<br/><br/>Common fields:<br/>  - name    (required) - Plugin identifier<br/>  - enabled (required) - Whether the plugin is enabled<br/><br/>Example (ontap-agent):<br/>  v1fs\_management\_plugins = [<br/>    {<br/>      name               = "ontap-agent"<br/>      enabled            = true<br/>      configMapName      = "ontap-agent-config"<br/>      securitySecretName = "ontap-agent-security"<br/>      jwtSecretName      = "ontap-agent-jwt"<br/>    }<br/>  ] | `list(map(any))` | `[]` | no |
| <a name="input_v1fs_namespace"></a> [v1fs\_namespace](#input\_v1fs\_namespace) | Kubernetes namespace for V1FS deployment | `string` | `"visionone-filesecurity"` | no |
| <a name="input_v1fs_proxy_url"></a> [v1fs\_proxy\_url](#input\_v1fs\_proxy\_url) | HTTP/HTTPS proxy URL for V1FS services (optional) | `string` | `""` | no |
| <a name="input_v1fs_registration_token"></a> [v1fs\_registration\_token](#input\_v1fs\_registration\_token) | Vision One File Security registration token for scanner authentication.<br/><br/>This JWT token authenticates your scanner with Vision One cloud service.<br/>The token is region-specific and determines which Vision One region<br/>your scanner connects to.<br/><br/>How to obtain:<br/>1. Log in to Vision One console (https://portal.xdr.trendmicro.com/)<br/>2. Navigate to: File Security → Containerized Scanner<br/>3. Click "Add Scanner" or "Get Registration Token"<br/>4. Copy the token (starts with "eyJ...")<br/><br/>Security note:<br/>- This is a sensitive credential<br/>- Do NOT commit to version control<br/>- Store in terraform.tfvars (which should be .gitignored)<br/>- Or use environment variable: TF\_VAR\_v1fs\_registration\_token<br/><br/>Token format: JWT string starting with "eyJ0eXAiOiJKV1Qi..." | `string` | n/a | yes |
| <a name="input_v1fs_scan_cache_cpu_request"></a> [v1fs\_scan\_cache\_cpu\_request](#input\_v1fs\_scan\_cache\_cpu\_request) | CPU request for scan cache pods | `string` | `"250m"` | no |
| <a name="input_v1fs_scan_cache_memory_request"></a> [v1fs\_scan\_cache\_memory\_request](#input\_v1fs\_scan\_cache\_memory\_request) | Memory request for scan cache pods | `string` | `"512Mi"` | no |
| <a name="input_v1fs_scanner_autoscaling_max_replicas"></a> [v1fs\_scanner\_autoscaling\_max\_replicas](#input\_v1fs\_scanner\_autoscaling\_max\_replicas) | Maximum replicas for scanner autoscaling | `number` | `10` | no |
| <a name="input_v1fs_scanner_autoscaling_min_replicas"></a> [v1fs\_scanner\_autoscaling\_min\_replicas](#input\_v1fs\_scanner\_autoscaling\_min\_replicas) | Minimum replicas for scanner autoscaling | `number` | `2` | no |
| <a name="input_v1fs_scanner_cpu_request"></a> [v1fs\_scanner\_cpu\_request](#input\_v1fs\_scanner\_cpu\_request) | CPU request for scanner pods | `string` | `"800m"` | no |
| <a name="input_v1fs_scanner_memory_request"></a> [v1fs\_scanner\_memory\_request](#input\_v1fs\_scanner\_memory\_request) | Memory request for scanner pods | `string` | `"2Gi"` | no |
| <a name="input_v1fs_scanner_replicas"></a> [v1fs\_scanner\_replicas](#input\_v1fs\_scanner\_replicas) | Number of scanner replicas | `number` | `2` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where EKS cluster will be deployed | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_controller_installed"></a> [alb\_controller\_installed](#output\_alb\_controller\_installed) | Whether AWS Load Balancer Controller is installed |
| <a name="output_alb_controller_policy_arn"></a> [alb\_controller\_policy\_arn](#output\_alb\_controller\_policy\_arn) | ARN of IAM policy for AWS Load Balancer Controller |
| <a name="output_alb_controller_role_arn"></a> [alb\_controller\_role\_arn](#output\_alb\_controller\_role\_arn) | ARN of IAM role for AWS Load Balancer Controller |
| <a name="output_alb_controller_version"></a> [alb\_controller\_version](#output\_alb\_controller\_version) | Version of AWS Load Balancer Controller |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the EKS cluster |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ID attached to the EKS cluster |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | Kubernetes version of the cluster |
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Command to configure kubectl |
| <a name="output_get_ingress_info"></a> [get\_ingress\_info](#output\_get\_ingress\_info) | Command to get ingress information |
| <a name="output_get_nlb_dns"></a> [get\_nlb\_dns](#output\_get\_nlb\_dns) | Command to get NLB DNS name for ICAP |
| <a name="output_icap_enabled"></a> [icap\_enabled](#output\_icap\_enabled) | Whether ICAP service is enabled |
| <a name="output_icap_port"></a> [icap\_port](#output\_icap\_port) | ICAP service port |
| <a name="output_management_service_enabled"></a> [management\_service\_enabled](#output\_management\_service\_enabled) | Whether management service is enabled |
| <a name="output_management_service_endpoint"></a> [management\_service\_endpoint](#output\_management\_service\_endpoint) | Management service endpoint URL |
| <a name="output_next_steps"></a> [next\_steps](#output\_next\_steps) | Next steps after deployment |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the OIDC Provider for EKS |
| <a name="output_route53_managed"></a> [route53\_managed](#output\_route53\_managed) | Whether Route53 DNS records are managed by Terraform |
| <a name="output_route53_record_created"></a> [route53\_record\_created](#output\_route53\_record\_created) | Whether Route53 record was successfully created |
| <a name="output_scanner_alb_hostname"></a> [scanner\_alb\_hostname](#output\_scanner\_alb\_hostname) | ALB hostname for scanner service - USE THIS to create your DNS records |
| <a name="output_scanner_alb_zone_id"></a> [scanner\_alb\_zone\_id](#output\_scanner\_alb\_zone\_id) | ALB hosted zone ID for Route53 Alias records |
| <a name="output_scanner_dns_fqdn"></a> [scanner\_dns\_fqdn](#output\_scanner\_dns\_fqdn) | Fully qualified domain name for scanner |
| <a name="output_scanner_domain"></a> [scanner\_domain](#output\_scanner\_domain) | Scanner service domain name |
| <a name="output_scanner_endpoint"></a> [scanner\_endpoint](#output\_scanner\_endpoint) | Scanner service endpoint URL |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Subnet IDs used by EKS |
| <a name="output_subnet_type"></a> [subnet\_type](#output\_subnet\_type) | Type of subnets - public or private |
| <a name="output_v1fs_chart_version"></a> [v1fs\_chart\_version](#output\_v1fs\_chart\_version) | Version of the deployed V1FS Helm chart |
| <a name="output_v1fs_namespace"></a> [v1fs\_namespace](#output\_v1fs\_namespace) | Kubernetes namespace for Vision One File Security |
| <a name="output_v1fs_release_name"></a> [v1fs\_release\_name](#output\_v1fs\_release\_name) | Name of the V1FS Helm release |
| <a name="output_v1fs_release_version"></a> [v1fs\_release\_version](#output\_v1fs\_release\_version) | Version of the deployed V1FS Helm release |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID where EKS is deployed |
<!-- END_TF_DOCS -->

## DNS Configuration

### Option 1: Automatic Route53 Management

If you use Route53 for DNS, set `manage_route53_records = true` and provide your `route53_zone_id`. Terraform will automatically create the necessary A (Alias) records.

```hcl
manage_route53_records = true
route53_zone_id        = "Z0123456789ABC"
```

### Option 2: Manual DNS Configuration

If you use a different DNS provider (Cloudflare, GoDaddy, etc.), leave `manage_route53_records = false` (default) and manually create a CNAME record after deployment:

1. Run `terraform apply`
2. Get the ALB hostname from outputs: `terraform output scanner_alb_hostname`
3. Create a CNAME record in your DNS provider:
   - **Name**: your `v1fs_domain_name` (e.g., `scanner`)
   - **Value**: ALB hostname from output

## Troubleshooting

### Certificate Issues

```bash
# Verify certificate status
aws acm describe-certificate --certificate-arn <your-arn> --region <region>

# Check certificate covers your domain
aws acm describe-certificate --certificate-arn <your-arn> \
  --query 'Certificate.DomainValidationOptions'
```

### ALB Controller Issues

```bash
# Check ALB Controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# View ALB Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50

# Check ingress status
kubectl describe ingress -n visionone-filesecurity
```

### DNS Resolution Issues

```bash
# Wait 2-5 minutes for DNS propagation, then test
nslookup scanner.example.com

# Verify Route53 record (if using Route53)
aws route53 list-resource-record-sets --hosted-zone-id <zone-id> \
  --query "ResourceRecordSets[?Name=='scanner.example.com.']"
```

## Clean Up

```bash
terraform destroy
```

> **Note:** If `storage_class_reclaim_policy = "Retain"`, EBS volumes will not be automatically deleted. You must manually delete them from the AWS Console.

## Resources

- [Vision One File Security Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-file-security-containerized-scanner)
- [Helm Chart Documentation](https://trendmicro.github.io/visionone-file-security-helm/)
- [Vision One Console](https://portal.xdr.trendmicro.com/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Amazon EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)
