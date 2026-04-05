############################
# Global
############################
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

############################
# VPC
############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

############################
# Bastion
############################
variable "bastion_key_name" {
  description = "EC2 key pair name for bastion SSH access"
  type        = string
  default     = "newmain"
}

variable "bastion_ingress_cidr" {
  description = "Your IP CIDR allowed to SSH to the bastion"
  type        = string
  default     = "0.0.0.0/0"
}

############################
# EKS
############################
variable "cluster_name" {
  description = "EKS cluster name — used as prefix across all resources"
  type        = string
  default     = "prod-proj-fin"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.0"
}


