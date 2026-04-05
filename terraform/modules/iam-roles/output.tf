output "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  value       = aws_iam_role.eks_cluster.arn
}

output "karpenter_node_role_arn" {
  description = "IAM role ARN for Karpenter nodes"
  value       = aws_iam_role.karpenter_node.arn
}

output "karpenter_node_profile_arn" {
  description = "Instance profile ARN for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter_node.arn
}

output "karpenter_node_role_name" {
  value = aws_iam_role.karpenter_node.name
}

output "system_node_role_arn" {
  description = "IAM role ARN for system node group"
  value       = aws_iam_role.system_node_group.arn
}


output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}