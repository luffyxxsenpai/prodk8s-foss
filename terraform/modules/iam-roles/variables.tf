variable "cluster_name" {
  description = "EKS cluster name used for naming IAM roles"
  type        = string
}

variable "oidc_provider_arn" {
  type = string
}


