############################
# EKS Cluster
############################
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.eks_cluster_role_arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [var.control_plane_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

############################
# OIDC Provider (needed for IRSA)
############################
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.cluster_name}-oidc"
  }
}

############################
# System Node Group
# Runs Karpenter controller + CoreDNS + kube-proxy.
# Tainted CriticalAddonsOnly so workloads don't land here.
############################
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = var.system_node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  labels = {
    role = "system"
  }

  tags = {
    Name = "${var.cluster_name}-system-node"
  }
}

############################
# Access Entry
# Allows Karpenter-launched nodes to join the cluster
# via the API-based auth (requires authentication_mode API_AND_CONFIG_MAP)
############################
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.karpenter_node_role_arn
  type          = "EC2_LINUX"

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_access_entry" "root_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::537124957197:root"
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_access_policy_association" "root_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.root_user.principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.root_user]
}



resource "aws_security_group_rule" "vpc_to_system_nodes_all" {
  description       = "Allow all VPC traffic to system nodes"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  cidr_blocks       = [var.vpc_cidr]
}