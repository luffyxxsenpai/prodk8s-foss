output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "karpenter_controller_role_arn" {
  description = "Annotate the Karpenter service account with this ARN"
  value       = module.iam_karpenter_controller.karpenter_controller_role_arn
}

output "karpenter_node_role_name" {
  description = "Use in EC2NodeClass spec.role"
  value       = module.iam_roles.karpenter_node_role_name
}

output "karpenter_interruption_queue_name" {
  description = "Pass to Karpenter Helm chart settings.interruptionQueue"
  value       = module.karpenter_infra.queue_name
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}


output "argocd_password" {
  value = module.argocd.argocd_password_command
}