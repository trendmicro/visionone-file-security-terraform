output "storage_class_name" {
  description = "Name of the created StorageClass"
  value       = kubernetes_storage_class_v1.ebs.metadata[0].name
}
