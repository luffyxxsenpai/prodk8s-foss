variable "public_subnet_id" {
  description = "Public subnet ID for bastion host"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for bastion"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name (used for tagging)"
  type        = string
}