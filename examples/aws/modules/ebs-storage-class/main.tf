resource "kubernetes_storage_class_v1" "ebs" {
  metadata {
    name = var.storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = var.set_as_default ? "true" : "false"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = var.reclaim_policy

  parameters = {
    type      = var.volume_type
    encrypted = tostring(var.encrypted)
    fsType    = "ext4"
  }
}
