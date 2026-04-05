data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "karpenter_controller" {
  name = "KarpenterControllerRole-${var.cluster_name}"

  # Trust policy — only the Karpenter service account in karpenter ns
  # can assume this role, verified via OIDC JWT
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "KarpenterControllerPolicy"
  role = aws_iam_role.karpenter_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ── Read-only ─────────────────────────────────────────────────────────
      {
        Sid    = "EC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ssm:GetParameter",
          "pricing:GetProducts",
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },

      # ── Launch EC2 Instances (NO condition) ──────────────────────────────
      {
        Sid    = "EC2RunInstances"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
        ]
        Resource = "*"
      },

      # ── Create Launch Templates (WITH condition) ─────────────────────────
      {
        Sid    = "EC2CreateLaunchTemplate"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/karpenter.sh/cluster" = var.cluster_name
          }
        }
      },

      # ── Tagging ───────────────────────────────────────────────────────────
      {
        Sid    = "EC2Tagging"
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
          }
        }
      },

      # ── Terminate ─────────────────────────────────────────────────────────
      {
        Sid    = "EC2TerminateOwned"
        Effect = "Allow"
        Action = ["ec2:TerminateInstances"]
        Resource = "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/karpenter.sh/cluster" = var.cluster_name
          }
        }
      },

      # ── Delete launch templates ────────────────────────────────────────────
      {
        Sid    = "EC2DeleteOwnedLaunchTemplates"
        Effect = "Allow"
        Action = ["ec2:DeleteLaunchTemplate"]
        Resource = "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:launch-template/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/karpenter.sh/cluster" = var.cluster_name
          }
        }
      },

      # ── IAM ───────────────────────────────────────────────────────────────
      {
        Sid      = "IAMPassNodeRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.karpenter_node_role_arn
      },
      {
        Sid    = "IAMInstanceProfileAutoManagement"
        Effect = "Allow"
        Action = [
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
      },
      {
        Sid    = "IAMInstanceProfileTagging"
        Effect = "Allow"
        Action = ["iam:TagInstanceProfile"]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/karpenter.sh/cluster" = var.cluster_name
          }
        }
      },

      # ── SQS ───────────────────────────────────────────────────────────────
      {
        Sid    = "SQSInterruption"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = var.interruption_queue_arn
      }
    ]
  })
}