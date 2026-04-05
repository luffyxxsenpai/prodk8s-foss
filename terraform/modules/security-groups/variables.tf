variable "cluster_name" {
  description = "EKS cluster name used for naming security groups"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  type = string
}
variable "bastion_ingress_cidr" {
  description = "CIDR block allowed to SSH into bastion host"
  type        = string
}

