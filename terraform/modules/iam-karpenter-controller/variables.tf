variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from EKS"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "karpenter_node_role_arn" {
  description = "IAM role ARN used by Karpenter nodes"
  type        = string
}

variable "karpenter_node_profile_arn" {
  description = "Instance profile ARN used by Karpenter nodes"
  type        = string
}

variable "interruption_queue_arn" {
  description = "SQS queue ARN for interruption handling"
  type        = string
}