# Terraform Module for Vision One File Security

Terraform module to deploy [Trend Micro Vision One File Security](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-file-security-containerized-scanner) via Helm with simple syntax and minimal configuration.

## Helm Chart Documentation

For detailed Helm chart configuration, values, and advanced options, see the official Helm chart documentation:

**[https://trendmicro.github.io/visionone-file-security-helm/](https://trendmicro.github.io/visionone-file-security-helm/)**

## Usage

### Local Kubernetes (Minikube, Kind, Docker Desktop, Colima)

```hcl
module "v1fs" {
  source = "../../modules/v1fs"

  release_name       = "v1fs"
  chart_version      = "1.4.0"
  namespace          = "visionone-filesecurity"
  registration_token = var.registration_token

  # NGINX Ingress
  ingress_class_name = "nginx"
  domain_name        = "scanner.local.k8s"

  # Scanner Configuration
  scanner_replicas       = 1
  scanner_cpu_request    = "800m"
  scanner_memory_request = "2Gi"
}
```

### AWS EKS

```hcl
module "v1fs" {
  source = "../../modules/v1fs"

  release_name       = "v1fs"
  chart_version      = "1.4.0"
  namespace          = "visionone-filesecurity"
  registration_token = var.registration_token

  # AWS ALB Ingress
  ingress_class_name  = "alb"
  domain_name         = "scanner.example.com"
  alb_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"
  alb_scheme          = "internet-facing"

  # Scanner Configuration
  scanner_replicas                 = 2
  scanner_cpu_request              = "800m"
  scanner_memory_request           = "2Gi"
  enable_scanner_autoscaling       = true
  scanner_autoscaling_min_replicas = 2
  scanner_autoscaling_max_replicas = 10
}
```

### With Management Service (ONTAP Integration)

```hcl
module "v1fs" {
  source = "../../modules/v1fs"

  release_name       = "v1fs"
  chart_version      = "1.4.0"
  namespace          = "visionone-filesecurity"
  registration_token = var.registration_token

  ingress_class_name  = "alb"
  domain_name         = "scanner.example.com"
  alb_certificate_arn = var.certificate_arn

  # Enable Management Service
  enable_management = true
  management_plugins = [
    {
      name    = "ontap-agent"
      enabled = true
    }
  ]

  # Enable Database for Management
  enable_management_db          = true
  create_database_storage_class = false
  database_storage_class_name   = "gp3"
}
```

### Using Local Helm Chart

```hcl
module "v1fs" {
  source = "../../modules/v1fs"

  release_name       = "v1fs"
  namespace          = "visionone-filesecurity"
  registration_token = var.registration_token

  # Use local chart instead of remote repository
  chart_path = "../../../v1fs-helm/amaas-helm/visionone-filesecurity"

  ingress_class_name = "nginx"
  domain_name        = "scanner.local.k8s"
}
```

## Upgrading

To upgrade Vision One File Security to a newer version, simply update the `chart_version` in your `terraform.tfvars` or module configuration:

```hcl
# Before
chart_version = "1.4.0"

# After
chart_version = "1.5.0"
```

Then apply the changes:

```bash
terraform plan   # Review the upgrade changes
terraform apply  # Execute the upgrade
```

Terraform will detect the version change and trigger a Helm release upgrade. Helm handles the rolling update of pods automatically, ensuring minimal downtime.

> **Note:** Always review the [Helm Chart Release Notes](https://trendmicro.github.io/visionone-file-security-helm/) before upgrading to check for breaking changes or migration steps.

## Examples

Complete, ready-to-use examples are available in the [`examples/`](examples/) directory:

| Example | Description | Directory |
|---------|-------------|-----------|
| **Local Kubernetes** | Deploy to Minikube, Kind, Docker Desktop, or Colima with NGINX Ingress | [`examples/local/`](examples/local/) |
| **AWS EKS** | Full infrastructure including EKS cluster, VPC, ALB Controller, and V1FS | [`examples/aws/`](examples/aws/) |

### Quick Start with Examples

**Local Kubernetes:**
```bash
cd examples/local
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your registration token
terraform init
terraform apply
```

**AWS EKS:**
```bash
cd examples/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS and V1FS settings
terraform init
terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| Kubernetes | >= 1.24 |
| Helm | >= 3.0 |
| kubectl | configured for your cluster |

## Providers

| Name | Version |
|------|---------|
| helm | ~> 2.0 |
| kubernetes | ~> 2.0 |

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.v1fs](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.v1fs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.device_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.cleanup_database_pvc](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_certificate_arn"></a> [alb\_certificate\_arn](#input\_alb\_certificate\_arn) | ACM certificate ARN for HTTPS (required for AWS ALB, optional for other ingress controllers) | `string` | `""` | no |
| <a name="input_alb_scheme"></a> [alb\_scheme](#input\_alb\_scheme) | ALB scheme: internet-facing or internal | `string` | `"internet-facing"` | no |
| <a name="input_backend_communicator_cpu_request"></a> [backend\_communicator\_cpu\_request](#input\_backend\_communicator\_cpu\_request) | CPU request for backend communicator pods | `string` | `"250m"` | no |
| <a name="input_backend_communicator_memory_request"></a> [backend\_communicator\_memory\_request](#input\_backend\_communicator\_memory\_request) | Memory request for backend communicator pods | `string` | `"128Mi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name when using remote repository. Ignored when chart\_path is set. | `string` | `"visionone-filesecurity"` | no |
| <a name="input_chart_path"></a> [chart\_path](#input\_chart\_path) | Local path to Helm chart directory. When set, chart\_repository and chart\_version are ignored.<br/>Use this for development or on-premise deployments with local charts.<br/>Path is relative to the Terraform root module (where you call this module).<br/>Example: "../../../v1fs-helm/amaas-helm/visionone-filesecurity" | `string` | `null` | no |
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | Helm chart repository URL | `string` | `"https://trendmicro.github.io/visionone-file-security-helm/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version. Required when using remote repository (chart\_path is null). | `string` | `null` | no |
| <a name="input_create_database_storage_class"></a> [create\_database\_storage\_class](#input\_create\_database\_storage\_class) | Whether to create a StorageClass for database persistence. Set to false when using cloud provider storage classes (e.g., EBS gp3). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create the namespace. Set to false if the namespace already exists (e.g., using 'default' or pre-existing namespace) | `bool` | `true` | no |
| <a name="input_database_cpu_limit"></a> [database\_cpu\_limit](#input\_database\_cpu\_limit) | CPU limit for database container pods | `string` | `"500m"` | no |
| <a name="input_database_cpu_request"></a> [database\_cpu\_request](#input\_database\_cpu\_request) | CPU request for database container pods | `string` | `"250m"` | no |
| <a name="input_database_memory_limit"></a> [database\_memory\_limit](#input\_database\_memory\_limit) | Memory limit for database container pods | `string` | `"1Gi"` | no |
| <a name="input_database_memory_request"></a> [database\_memory\_request](#input\_database\_memory\_request) | Memory request for database container pods | `string` | `"512Mi"` | no |
| <a name="input_database_persistence_size"></a> [database\_persistence\_size](#input\_database\_persistence\_size) | Size of persistent volume for database (e.g., '10Gi', '100Gi') | `string` | `"100Gi"` | no |
| <a name="input_database_storage_class_host_path"></a> [database\_storage\_class\_host\_path](#input\_database\_storage\_class\_host\_path) | Host path for local StorageClass (only used when database\_storage\_class\_create = true) | `string` | `"/mnt/data/postgres"` | no |
| <a name="input_database_storage_class_name"></a> [database\_storage\_class\_name](#input\_database\_storage\_class\_name) | StorageClass name for database persistence. Use 'gp3' or 'gp2' for AWS EBS, or custom name for local/hostPath. | `string` | `"visionone-filesecurity-storage"` | no |
| <a name="input_database_storage_class_reclaim_policy"></a> [database\_storage\_class\_reclaim\_policy](#input\_database\_storage\_class\_reclaim\_policy) | Reclaim policy for the StorageClass: Delete or Retain | `string` | `"Retain"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress | `string` | n/a | yes |
| <a name="input_enable_icap"></a> [enable\_icap](#input\_enable\_icap) | [NOT PRODUCTION READY] Enable ICAP service with NLB.<br/><br/>⚠️ WARNING: ICAP feature is NOT READY for production use!<br/>Currently, only gRPC protocol is supported and stable.<br/>ICAP support is under development and should remain disabled.<br/><br/>Use gRPC protocol instead for production deployments. | `bool` | `false` | no |
| <a name="input_enable_management"></a> [enable\_management](#input\_enable\_management) | Whether to enable management service | `bool` | `false` | no |
| <a name="input_enable_management_db"></a> [enable\_management\_db](#input\_enable\_management\_db) | Whether to enable PostgreSQL database container for management service. Requires enable\_management = true. | `bool` | `false` | no |
| <a name="input_enable_scan_cache"></a> [enable\_scan\_cache](#input\_enable\_scan\_cache) | Enable scan result caching | `bool` | `true` | no |
| <a name="input_enable_scanner_autoscaling"></a> [enable\_scanner\_autoscaling](#input\_enable\_scanner\_autoscaling) | Whether to enable autoscaling for scanner | `bool` | `false` | no |
| <a name="input_extra_helm_values"></a> [extra\_helm\_values](#input\_extra\_helm\_values) | Additional Helm values as a list of YAML strings. Applied after module defaults.<br/>Later entries override earlier ones using Helm's deep merge strategy.<br/>Useful for injecting values from files or complex configurations not covered by module variables.<br/><br/>Example:<br/>  extra\_helm\_values = [<br/>    file("custom-values.yaml"),<br/>    yamlencode({<br/>      scanner = {<br/>        nodeSelector = { "node-type" = "scanner" }<br/>        tolerations = [{<br/>          key    = "dedicated"<br/>          value  = "scanner"<br/>          effect = "NoSchedule"<br/>        }]<br/>      }<br/>    })<br/>  ] | `list(string)` | `[]` | no |
| <a name="input_icap_certificate_arn"></a> [icap\_certificate\_arn](#input\_icap\_certificate\_arn) | ACM certificate ARN for ICAP TLS (optional) | `string` | `""` | no |
| <a name="input_icap_nlb_scheme"></a> [icap\_nlb\_scheme](#input\_icap\_nlb\_scheme) | NLB scheme for ICAP: internet-facing or internal | `string` | `"internet-facing"` | no |
| <a name="input_icap_port"></a> [icap\_port](#input\_icap\_port) | ICAP service port | `number` | `1344` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | List of Kubernetes secret names for pulling images from private registries.<br/>Applied globally to all V1FS components (scanner, scanCache, backendCommunicator, managementService, databaseContainer).<br/><br/>Example: image\_pull\_secrets = ["my-registry-secret"] | `list(string)` | `[]` | no |
| <a name="input_ingress_class_name"></a> [ingress\_class\_name](#input\_ingress\_class\_name) | Ingress class name (e.g., 'alb', 'nginx', 'gce') | `string` | `"alb"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for V1FS services | `string` | `"INFO"` | no |
| <a name="input_management_cpu_request"></a> [management\_cpu\_request](#input\_management\_cpu\_request) | CPU request for management service pods | `string` | `"250m"` | no |
| <a name="input_management_extra_ingress_annotations"></a> [management\_extra\_ingress\_annotations](#input\_management\_extra\_ingress\_annotations) | Additional annotations for management ingress (merged with defaults) | `map(string)` | `{}` | no |
| <a name="input_management_memory_request"></a> [management\_memory\_request](#input\_management\_memory\_request) | Memory request for management service pods | `string` | `"256Mi"` | no |
| <a name="input_management_plugins"></a> [management\_plugins](#input\_management\_plugins) | Management service plugins configuration.<br/>Each plugin is a map with plugin-specific fields.<br/><br/>Common fields:<br/>  - name    (required) - Plugin identifier<br/>  - enabled (required) - Whether the plugin is enabled<br/><br/>Example (ontap-agent):<br/>  management\_plugins = [<br/>    {<br/>      name               = "ontap-agent"<br/>      enabled            = true<br/>      configMapName      = "ontap-agent-config"<br/>      securitySecretName = "ontap-agent-security"<br/>      jwtSecretName      = "ontap-agent-jwt"<br/>    }<br/>  ] | `list(map(any))` | `[]` | no |
| <a name="input_management_websocket_prefix"></a> [management\_websocket\_prefix](#input\_management\_websocket\_prefix) | WebSocket path prefix for the management service | `string` | `"/ontap"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for V1FS deployment | `string` | `"visionone-filesecurity"` | no |
| <a name="input_no_proxy"></a> [no\_proxy](#input\_no\_proxy) | Comma-separated no\_proxy list for all V1FS components | `string` | `"localhost,127.0.0.1,.svc.cluster.local"` | no |
| <a name="input_proxy_url"></a> [proxy\_url](#input\_proxy\_url) | HTTP/HTTPS proxy URL | `string` | `""` | no |
| <a name="input_registration_token"></a> [registration\_token](#input\_registration\_token) | Vision One registration token | `string` | n/a | yes |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Helm release name | `string` | n/a | yes |
| <a name="input_scan_cache_cpu_request"></a> [scan\_cache\_cpu\_request](#input\_scan\_cache\_cpu\_request) | CPU request for scan cache pods | `string` | `"250m"` | no |
| <a name="input_scan_cache_memory_request"></a> [scan\_cache\_memory\_request](#input\_scan\_cache\_memory\_request) | Memory request for scan cache pods | `string` | `"512Mi"` | no |
| <a name="input_scanner_autoscaling_max_replicas"></a> [scanner\_autoscaling\_max\_replicas](#input\_scanner\_autoscaling\_max\_replicas) | Maximum replicas for scanner autoscaling | `number` | `10` | no |
| <a name="input_scanner_autoscaling_min_replicas"></a> [scanner\_autoscaling\_min\_replicas](#input\_scanner\_autoscaling\_min\_replicas) | Minimum replicas for scanner autoscaling | `number` | `1` | no |
| <a name="input_scanner_config_map_name"></a> [scanner\_config\_map\_name](#input\_scanner\_config\_map\_name) | ConfigMap name for scanner configuration | `string` | `"scanner-config"` | no |
| <a name="input_scanner_cpu_request"></a> [scanner\_cpu\_request](#input\_scanner\_cpu\_request) | CPU request for scanner pods | `string` | `"800m"` | no |
| <a name="input_scanner_extra_ingress_annotations"></a> [scanner\_extra\_ingress\_annotations](#input\_scanner\_extra\_ingress\_annotations) | Additional annotations for scanner ingress (merged with defaults) | `map(string)` | `{}` | no |
| <a name="input_scanner_memory_request"></a> [scanner\_memory\_request](#input\_scanner\_memory\_request) | Memory request for scanner pods | `string` | `"2Gi"` | no |
| <a name="input_scanner_replicas"></a> [scanner\_replicas](#input\_scanner\_replicas) | Number of scanner replicas | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chart_source"></a> [chart\_source](#output\_chart\_source) | Helm chart source (local path or repository URL) |
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Helm chart version |
| <a name="output_database_enabled"></a> [database\_enabled](#output\_database\_enabled) | Whether PostgreSQL database is enabled for management service |
| <a name="output_device_token_secret_name"></a> [device\_token\_secret\_name](#output\_device\_token\_secret\_name) | Name of the device token secret |
| <a name="output_icap_enabled"></a> [icap\_enabled](#output\_icap\_enabled) | Whether ICAP service is enabled |
| <a name="output_is_local_chart"></a> [is\_local\_chart](#output\_is\_local\_chart) | Whether using local Helm chart |
| <a name="output_management_enabled"></a> [management\_enabled](#output\_management\_enabled) | Whether management service is enabled |
| <a name="output_management_endpoint"></a> [management\_endpoint](#output\_management\_endpoint) | Management service endpoint |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace name |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Helm release name |
| <a name="output_release_version"></a> [release\_version](#output\_release\_version) | Deployed Helm release version |
| <a name="output_scanner_endpoint"></a> [scanner\_endpoint](#output\_scanner\_endpoint) | Scanner service endpoint |
| <a name="output_token_secret_name"></a> [token\_secret\_name](#output\_token\_secret\_name) | Name of the token secret |
<!-- END_TF_DOCS -->

## Getting Your Registration Token

1. Log in to [Vision One Console](https://portal.xdr.trendmicro.com/)
2. Navigate to: **File Security** → **Containerized Scanner**
3. Click **Add Scanner** or **Get Registration Token**
4. Copy the token (starts with `eyJ...`)

## Resources

- [Vision One File Security Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-file-security-containerized-scanner)
- [Helm Chart Documentation](https://trendmicro.github.io/visionone-file-security-helm/)
- [Vision One Console](https://portal.xdr.trendmicro.com/)

## Important Notes

1. **ICAP Protocol:** Currently NOT supported. Use gRPC only.
3. **Certificate:** For AWS ALB, certificate must be in `Issued` status before deployment.
4. **Region:** ACM certificate must be in the same region as your EKS cluster.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## Code of Conduct

This project has adopted the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read it to understand the expectations for participation in this community.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
