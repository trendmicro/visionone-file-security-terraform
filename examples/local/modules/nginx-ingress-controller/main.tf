resource "helm_release" "nginx_ingress" {
  count = var.create_helm_release ? 1 : 0

  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  wait            = true

  values = [yamlencode({
    controller = {
      service = {
        type = var.service_type
      }

      replicaCount = var.replica_count

      resources = {
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
      }

      admissionWebhooks = {
        enabled = var.enable_admission_webhooks
      }
    }
  })]
}

data "kubernetes_service" "nginx_ingress" {
  count = var.create_helm_release ? 1 : 0

  metadata {
    name      = "ingress-nginx-controller"
    namespace = helm_release.nginx_ingress[0].namespace
  }

  depends_on = [helm_release.nginx_ingress]
}
