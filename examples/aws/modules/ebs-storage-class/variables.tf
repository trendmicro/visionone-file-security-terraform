variable "storage_class_name" {
  description = "Name of the StorageClass to create"
  type        = string
  default     = "visionone-filesecurity-storage"
}

variable "volume_type" {
  description = "EBS volume type: gp3, gp2, io1, or io2"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.volume_type)
    error_message = "volume_type must be one of: gp3, gp2, io1, io2."
  }
}

variable "set_as_default" {
  description = "Whether to set this StorageClass as the cluster default"
  type        = bool
  default     = false
}

variable "encrypted" {
  description = "Whether to encrypt EBS volumes"
  type        = bool
  default     = true
}

variable "reclaim_policy" {
  description = "Reclaim policy for StorageClass: Delete or Retain"
  type        = string
  default     = "Delete"

  validation {
    condition     = contains(["Delete", "Retain"], var.reclaim_policy)
    error_message = "reclaim_policy must be 'Delete' or 'Retain'."
  }
}
