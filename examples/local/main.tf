provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "nginx_ingress_controller" {
  count  = var.create_nginx_ingress_controller ? 1 : 0
  source = "./modules/nginx-ingress-controller"

  namespace                 = "ingress-nginx"
  chart_version             = var.nginx_ingress_controller_version
  service_type              = var.nginx_service_type
  create_helm_release       = true
  enable_admission_webhooks = false
}

module "v1fs" {
  source = "../../modules/v1fs"

  namespace        = var.v1fs_namespace
  create_namespace = var.create_v1fs_namespace
  release_name     = var.project_name
  chart_version    = var.v1fs_helm_chart_version

  registration_token = var.v1fs_registration_token

  log_level         = var.v1fs_log_level
  enable_scan_cache = var.enable_v1fs_scan_cache
  proxy_url         = var.v1fs_proxy_url

  scanner_replicas                 = var.v1fs_scanner_replicas
  enable_scanner_autoscaling       = var.enable_v1fs_scanner_autoscaling
  scanner_autoscaling_min_replicas = var.v1fs_scanner_autoscaling_min_replicas
  scanner_autoscaling_max_replicas = var.v1fs_scanner_autoscaling_max_replicas
  scanner_cpu_request              = var.v1fs_scanner_cpu_request
  scanner_memory_request           = var.v1fs_scanner_memory_request

  ingress_class_name = "nginx"
  domain_name        = var.v1fs_domain_name

  enable_management         = var.enable_v1fs_management
  management_cpu_request    = var.v1fs_management_cpu_request
  management_memory_request = var.v1fs_management_memory_request
  management_plugins        = var.v1fs_management_plugins

  enable_icap = false

  scan_cache_cpu_request    = var.v1fs_scan_cache_cpu_request
  scan_cache_memory_request = var.v1fs_scan_cache_memory_request

  backend_communicator_cpu_request    = var.v1fs_backend_communicator_cpu_request
  backend_communicator_memory_request = var.v1fs_backend_communicator_memory_request

  chart_path = var.v1fs_chart_path

  image_pull_secrets = var.v1fs_image_pull_secrets

  enable_management_db             = var.enable_v1fs_management_db
  database_persistence_size        = var.v1fs_database_persistence_size
  create_database_storage_class    = true
  database_storage_class_host_path = var.v1fs_database_storage_class_host_path

  depends_on = [
    module.nginx_ingress_controller
  ]
}
