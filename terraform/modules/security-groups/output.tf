output "control_plane_sg_id" {
  description = "Security group ID for EKS control plane"
  value       = aws_security_group.control_plane.id
}

output "karpenter_node_sg_id" {
  description = "Security group ID for Karpenter nodes"
  value       = aws_security_group.karpenter_node.id
}

output "bastion_sg_id" {
  description = "Security group ID for bastion host"
  value       = aws_security_group.bastion.id
}