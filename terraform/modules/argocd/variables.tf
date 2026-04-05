variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}


variable "argocd_chart_version" {
  description = "Pinned ArgoCD Helm chart version"
  type        = string
  default     = "7.7.0"
}


variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}


variable "interruption_queue" {
  type        = string
}


variable "karpenter_controller_role_arn" {
  type        = string
}




