############################
# SQS Interruption Queue
############################
resource "aws_sqs_queue" "interruption" {
  name                      = "Karpenter-${var.cluster_name}"
  message_retention_seconds = 300

  tags = {
    Name = "Karpenter-${var.cluster_name}"
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.interruption.arn
    }]
  })
}

############################
# EventBridge Rules → SQS
############################
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "KarpenterSpotInterruption-${var.cluster_name}"
  description = "Spot instance interruption warning — 2 min notice"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}
resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule = aws_cloudwatch_event_rule.spot_interruption.name
  arn  = aws_sqs_queue.interruption.arn
}

resource "aws_cloudwatch_event_rule" "rebalance" {
  name        = "KarpenterRebalance-${var.cluster_name}"
  description = "EC2 instance rebalance recommendation"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })
}
resource "aws_cloudwatch_event_target" "rebalance" {
  rule = aws_cloudwatch_event_rule.rebalance.name
  arn  = aws_sqs_queue.interruption.arn
}

resource "aws_cloudwatch_event_rule" "instance_state" {
  name        = "KarpenterInstanceState-${var.cluster_name}"
  description = "EC2 instance state change notification"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
}
resource "aws_cloudwatch_event_target" "instance_state" {
  rule = aws_cloudwatch_event_rule.instance_state.name
  arn  = aws_sqs_queue.interruption.arn
}

resource "aws_cloudwatch_event_rule" "health" {
  name        = "KarpenterHealth-${var.cluster_name}"
  description = "AWS Health EC2 events"
  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
}
resource "aws_cloudwatch_event_target" "health" {
  rule = aws_cloudwatch_event_rule.health.name
  arn  = aws_sqs_queue.interruption.arn
}
