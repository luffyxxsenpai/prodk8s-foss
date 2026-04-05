output "queue_arn" {
  description = "ARN of the Karpenter interruption SQS queue"
  value       = aws_sqs_queue.interruption.arn
}

output "queue_name" {
  value = aws_sqs_queue.interruption.name
}