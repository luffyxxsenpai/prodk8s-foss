output "karpenter_controller_role_arn" {
  description = "IAM role ARN for Karpenter controller"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_controller_role_name" {
  value = aws_iam_role.karpenter_controller.name
}

