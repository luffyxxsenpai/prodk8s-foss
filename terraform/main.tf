############################
# VPC
############################
module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

############################
# Security Groups
############################

module "security_groups" {
  source               = "./modules/security-groups"
  cluster_name         = var.cluster_name
  vpc_id               = module.vpc.vpc_id
  bastion_ingress_cidr = var.bastion_ingress_cidr
  vpc_cidr             = var.vpc_cidr

}

############################
# IAM Pass 1 — node roles (no OIDC needed yet)
# cluster role, system node role, karpenter node role + instance profile
############################
module "iam_roles" {
  source = "./modules/iam-roles"
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name = var.cluster_name
}

############################
# EKS Cluster + System Node Group + OIDC provider
############################
module "eks" {
  source     = "./modules/eks"
  depends_on = [module.vpc, module.security_groups]


  cluster_name            = var.cluster_name
  vpc_cidr                = var.vpc_cidr
  cluster_version         = var.cluster_version
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  control_plane_sg_id     = module.security_groups.control_plane_sg_id
  eks_cluster_role_arn    = module.iam_roles.eks_cluster_role_arn
  system_node_role_arn    = module.iam_roles.system_node_role_arn
  karpenter_node_role_arn = module.iam_roles.karpenter_node_role_arn
}

module "argocd" {
  source = "./modules/argocd"

  depends_on = [module.eks, module.karpenter_infra, module.iam_karpenter_controller]

  cluster_name                  = module.eks.cluster_name                  
  cluster_endpoint              = module.eks.cluster_endpoint              
  interruption_queue            = module.karpenter_infra.queue_name        
  karpenter_controller_role_arn = module.iam_karpenter_controller.karpenter_controller_role_arn
  argocd_chart_version = var.argocd_chart_version 
}

############################
# Karpenter Infra — SQS + EventBridge
############################
module "karpenter_infra" {
  source = "./modules/karpenter-infra"

  cluster_name = var.cluster_name
}

############################
# IAM Pass 2 — Karpenter controller role
# Needs OIDC (from eks module) and queue ARN (from karpenter_infra)
############################
module "iam_karpenter_controller" {
  source = "./modules/iam-karpenter-controller"

  cluster_name               = var.cluster_name
  oidc_provider_url          = module.eks.oidc_issuer_url
  oidc_provider_arn          = module.eks.oidc_provider_arn
  karpenter_node_role_arn    = module.iam_roles.karpenter_node_role_arn
  karpenter_node_profile_arn = module.iam_roles.karpenter_node_profile_arn
  interruption_queue_arn     = module.karpenter_infra.queue_arn
}

############################
# Bastion
############################
module "bastion" {
  source = "./modules/bastion"

  cluster_name     = var.cluster_name
  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_sg_id    = module.security_groups.bastion_sg_id
  key_name         = var.bastion_key_name
}



############# EBS CSI DRIVER

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.23.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.iam_roles.ebs_csi_role_arn
    }
  }

  depends_on = [module.eks, module.iam_roles]
}