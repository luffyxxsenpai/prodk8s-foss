variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS"
  type        = list(string)
}

variable "control_plane_sg_id" {
  description = "Security group ID for EKS control plane"
  type        = string
}

variable "system_node_role_arn" {
  description = "IAM role ARN for system node group"
  type        = string
}

variable "karpenter_node_role_arn" {
  description = "IAM role ARN for Karpenter nodes"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

