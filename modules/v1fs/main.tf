resource "kubernetes_namespace" "v1fs" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      app  = "visionone-filesecurity"
    }
  }
}

resource "kubernetes_secret" "token" {
  metadata {
    name      = "token-secret"
    namespace = var.namespace
  }

  data = {
    registration-token = var.registration_token
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.v1fs,
  ]
}

resource "kubernetes_secret" "device_token" {
  metadata {
    name      = "device-token-secret"
    namespace = var.namespace
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.v1fs,
  ]
}

locals {
  use_local_chart = var.chart_path != null

  image_pull_secrets_formatted = [
    for secret in var.image_pull_secrets : { name = secret }
  ]

  scanner_alb_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"                   = var.alb_scheme
      "alb.ingress.kubernetes.io/backend-protocol-version" = "GRPC"
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      "alb.ingress.kubernetes.io/group.name"               = "v1fs-ctr-group"
    },
    var.alb_certificate_arn != "" ? {
      "alb.ingress.kubernetes.io/certificate-arn" = var.alb_certificate_arn
    } : {}
  )

  scanner_nginx_annotations = {
    "nginx.ingress.kubernetes.io/backend-protocol" = "GRPC"
  }

  scanner_default_annotations = var.ingress_class_name == "alb" ? local.scanner_alb_annotations : local.scanner_nginx_annotations

  # Management service annotations based on ingress class
  management_alb_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"                   = var.alb_scheme
      "alb.ingress.kubernetes.io/backend-protocol"         = "HTTP"
      "alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP1"
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      "alb.ingress.kubernetes.io/group.name"               = "v1fs-ctr-group"
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=300"
      "alb.ingress.kubernetes.io/target-group-attributes"  = "stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=86400"
    },
    var.alb_certificate_arn != "" ? {
      "alb.ingress.kubernetes.io/certificate-arn" = var.alb_certificate_arn
    } : {}
  )

  management_nginx_annotations = {
    "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
  }

  management_default_annotations = var.ingress_class_name == "alb" ? local.management_alb_annotations : local.management_nginx_annotations

  # Global V1FS configuration
  global_config = {
    tokenSecretName       = kubernetes_secret.token.metadata[0].name
    deviceTokenSecretName = kubernetes_secret.device_token.metadata[0].name
    logLevel              = var.log_level
    enableScanCache       = var.enable_scan_cache
    proxyUrl              = var.proxy_url
    noProxy               = var.no_proxy

    scanner = {
      configMapName = var.scanner_config_map_name
    }

    management = {
      dbEnabled                = var.enable_management_db
      ontapWebSocketPathPrefix = var.management_websocket_prefix
      plugins                  = var.management_plugins
    }
  }

  scanner_config = {
    replicaCount = var.scanner_replicas

    imagePullSecrets = local.image_pull_secrets_formatted
    nameOverride     = ""
    fullnameOverride = ""

    serviceAccount = {
      create      = true
      automount   = true
      annotations = {}
      name        = "scanner"
    }

    rbac = {
      create = true
    }

    podAnnotations     = {}
    podLabels          = {}
    podSecurityContext = {}
    securityContext    = {}

    service = {
      type     = "ClusterIP"
      port     = 50051
      icapPort = 1344
    }

    resources = {
      requests = {
        cpu    = var.scanner_cpu_request
        memory = var.scanner_memory_request
      }
    }

    livenessProbe = {
      exec = {
        command = ["sh", "-c", "v1fs-health-checker"]
      }
      initialDelaySeconds = 30
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    readinessProbe = {
      exec = {
        command = ["sh", "-c", "v1fs-health-checker"]
      }
      initialDelaySeconds = 30
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    autoscaling = {
      enabled                           = var.enable_scanner_autoscaling
      minReplicas                       = var.scanner_autoscaling_min_replicas
      maxReplicas                       = var.scanner_autoscaling_max_replicas
      targetCPUUtilizationPercentage    = 80
      targetMemoryUtilizationPercentage = 80
    }

    ingress = {
      enabled   = true
      className = var.ingress_class_name
      annotations = merge(
        local.scanner_default_annotations,
        var.scanner_extra_ingress_annotations
      )
      hosts = [{
        host = var.domain_name
        paths = [{
          path     = "/"
          pathType = "Prefix"
        }]
      }]
      tls = []
    }

    extraVolumes      = []
    extraVolumeMounts = []
    nodeSelector      = {}
    tolerations       = []
    affinity          = {}
  }

  management_config = {
    enabled      = var.enable_management
    replicaCount = var.enable_management ? 1 : 0

    imagePullSecrets = local.image_pull_secrets_formatted
    nameOverride     = ""
    fullnameOverride = ""

    serviceAccount = {
      create      = var.enable_management
      automount   = var.enable_management
      annotations = {}
      name        = var.enable_management ? "management-service" : ""
    }

    rbac = {
      create = var.enable_management
    }

    podAnnotations     = {}
    podLabels          = {}
    podSecurityContext = {}
    securityContext    = {}

    service = {
      type        = "ClusterIP"
      port        = 8080
      ontapWsPort = 8081
    }

    resources = {
      requests = {
        cpu    = var.enable_management ? var.management_cpu_request : "0"
        memory = var.enable_management ? var.management_memory_request : "0"
      }
    }

    livenessProbe = {
      httpGet = {
        path = "/health"
        port = "http"
      }
      initialDelaySeconds = 10
      periodSeconds       = 60
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    readinessProbe = {
      httpGet = {
        path = "/health"
        port = "http"
      }
      initialDelaySeconds = 10
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    ingress = {
      enabled   = var.enable_management
      className = var.enable_management ? var.ingress_class_name : ""
      annotations = var.enable_management ? merge(
        local.management_default_annotations,
        var.management_extra_ingress_annotations
      ) : {}
      hosts = var.enable_management ? [{
        host = var.domain_name
        paths = [{
          path     = var.management_websocket_prefix
          pathType = "Prefix"
        }]
      }] : []
      tls = []
    }

    nodeSelector = {}
    tolerations  = []
    affinity     = {}
  }

  icap_config = var.enable_icap ? {
    externalService = {
      enabled = true
      annotations = merge(
        {
          "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = var.icap_nlb_scheme
        },
        var.icap_certificate_arn != "" ? {
          "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = var.icap_certificate_arn
        } : {}
      )
      icapPort = var.icap_port
    }
    } : {
    externalService = {
      enabled     = false
      annotations = {}
      icapPort    = 1344
    }
  }

  scan_cache_config = {
    replicaCount = 1

    image = {
      pullPolicy = "Always"
    }

    imagePullSecrets = local.image_pull_secrets_formatted
    nameOverride     = ""
    fullnameOverride = ""

    serviceAccount = {
      create      = true
      automount   = true
      annotations = {}
      name        = "scan-cache"
    }

    podAnnotations     = {}
    podLabels          = {}
    podSecurityContext = {}
    securityContext    = {}

    service = {
      type       = "ClusterIP"
      port       = 6379
      targetPort = 6379
    }

    resources = {
      requests = {
        memory = var.scan_cache_memory_request
        cpu    = var.scan_cache_cpu_request
      }
    }

    livenessProbe = {
      exec = {
        command = ["sh", "-c", "valkey-cli --raw ping"]
      }
      initialDelaySeconds = 30
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    readinessProbe = {
      exec = {
        command = ["sh", "-c", "valkey-cli --raw ping"]
      }
      initialDelaySeconds = 30
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    volumes      = []
    volumeMounts = []
    nodeSelector = {}
    tolerations  = []
    affinity     = {}
  }

  backend_communicator_config = {
    replicaCount = 1

    image = {
      pullPolicy = "Always"
    }

    imagePullSecrets = local.image_pull_secrets_formatted
    nameOverride     = ""
    fullnameOverride = ""

    serviceAccount = {
      create      = true
      automount   = true
      annotations = {}
      name        = "backend-communicator"
    }

    rbac = {
      create = true
    }

    podAnnotations     = {}
    podLabels          = {}
    podSecurityContext = {}
    securityContext    = {}

    service = {
      type       = "ClusterIP"
      port       = 8080
      targetPort = 8080
    }

    resources = {
      requests = {
        memory = var.backend_communicator_memory_request
        cpu    = var.backend_communicator_cpu_request
      }
    }

    livenessProbe = {
      exec = {
        command = ["sh", "-c", "v1fs-health-checker"]
      }
      initialDelaySeconds = 30
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    readinessProbe = {
      exec = {
        command = ["sh", "-c", "v1fs-health-checker"]
      }
      initialDelaySeconds = 30
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    volumes      = []
    volumeMounts = []
    nodeSelector = {}
    tolerations  = []
    affinity     = {}
  }

  database_config = {
    replicaCount = var.enable_management_db ? 1 : 0

    imagePullSecrets = local.image_pull_secrets_formatted
    nameOverride     = ""
    fullnameOverride = ""

    serviceAccount = {
      create      = var.enable_management_db
      automount   = var.enable_management_db
      annotations = {}
      name        = var.enable_management_db ? "database-container" : ""
    }

    rbac = {
      create = var.enable_management_db
    }

    podSecurityContext = {
      fsGroup    = 60000
      runAsUser  = 60000
      runAsGroup = 60000
    }

    service = {
      type       = "ClusterIP"
      port       = 5432
      targetPort = 5432
    }

    persistence = {
      storageClassName = var.database_storage_class_name
      size             = var.database_persistence_size
    }

    storageClass = {
      create        = var.create_database_storage_class
      name          = var.database_storage_class_name
      hostPath      = var.database_storage_class_host_path
      reclaimPolicy = var.database_storage_class_reclaim_policy
    }

    resources = {
      requests = {
        cpu    = var.database_cpu_request
        memory = var.database_memory_request
      }
      limits = {
        cpu    = var.database_cpu_limit
        memory = var.database_memory_limit
      }
    }

    livenessProbe = {
      exec = {
        command = ["sh", "-c", "pg_isready -h /tmp -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      }
      initialDelaySeconds = 60
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    readinessProbe = {
      exec = {
        command = ["sh", "-c", "pg_isready -h /tmp -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      }
      initialDelaySeconds = 60
      periodSeconds       = 30
      timeoutSeconds      = 10
      failureThreshold    = 3
    }

    nodeSelector = {}
    tolerations  = []
    affinity     = {}
  }

  # Merge all configurations
  helm_values = merge(
    {
      visiononeFilesecurity = local.global_config
      scanner               = local.scanner_config
      managementService     = local.management_config
      scanCache             = local.scan_cache_config
      backendCommunicator   = local.backend_communicator_config
      databaseContainer     = local.database_config
    },
    local.icap_config
  )
}

resource "null_resource" "cleanup_database_pvc" {
  count = var.enable_management_db ? 1 : 0

  triggers = {
    namespace    = var.namespace
    release_name = var.release_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if command -v kubectl >/dev/null 2>&1; then
        echo "Cleaning up PVCs for release ${self.triggers.release_name} in namespace ${self.triggers.namespace}..."
        kubectl delete pvc -l app.kubernetes.io/instance=${self.triggers.release_name} -n ${self.triggers.namespace} --ignore-not-found=true --wait=false 2>&1 || \
          echo "WARNING: Failed to delete PVCs. Manual cleanup may be required: kubectl delete pvc -l app.kubernetes.io/instance=${self.triggers.release_name} -n ${self.triggers.namespace}"
      else
        echo "WARNING: kubectl not found. Manual PVC cleanup required:"
        echo "  kubectl delete pvc -l app.kubernetes.io/instance=${self.triggers.release_name} -n ${self.triggers.namespace}"
      fi
    EOT

    on_failure = continue
  }

  depends_on = [
    helm_release.v1fs,
  ]
}

resource "helm_release" "v1fs" {
  name             = var.release_name
  repository       = local.use_local_chart ? null : var.chart_repository
  chart            = local.use_local_chart ? var.chart_path : var.chart_name
  version          = local.use_local_chart ? null : var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  wait            = true

  values = concat(
    [yamlencode(local.helm_values)],
    var.extra_helm_values
  )

  depends_on = [
    kubernetes_namespace.v1fs,
    kubernetes_secret.token,
    kubernetes_secret.device_token,
  ]

  lifecycle {
    precondition {
      condition     = local.use_local_chart || var.chart_version != null
      error_message = "chart_version is required when using remote repository (chart_path is null)."
    }

    precondition {
      condition     = var.ingress_class_name != "alb" || var.alb_certificate_arn != ""
      error_message = <<-EOT
        alb_certificate_arn is required when using ALB ingress controller.

        ALB requires an ACM certificate for HTTPS/gRPC traffic.

        Steps to fix:
        1. Create or identify an ACM certificate covering your domain
        2. Ensure the certificate is in 'Issued' status
        3. Set alb_certificate_arn = "arn:aws:acm:REGION:ACCOUNT:certificate/ID"

        If using nginx ingress instead, set ingress_class_name = "nginx"
      EOT
    }
  }
}
