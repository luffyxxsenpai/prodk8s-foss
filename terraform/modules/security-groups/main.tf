############################
# 1. Control Plane SG
#    Attached to the EKS cluster itself.
#    Only accepts traffic from known sources.
############################
resource "aws_security_group" "control_plane" {
  name        = "${var.cluster_name}-control-plane-sg"
  description = "EKS control plane  accepts traffic from nodes and bastion only"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-control-plane-sg"
  }
}

############################
# 2. Karpenter Node SG
#    Attached to every EC2 node Karpenter launches.
#    Tagged so Karpenter can discover it.
############################
resource "aws_security_group" "karpenter_node" {
  name        = "${var.cluster_name}-karpenter-node-sg"
  description = "Karpenter-managed nodes  allows cluster traffic and node-to-node"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound nodes need internet via NAT for image pulls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                     = "${var.cluster_name}-karpenter-node-sg"
    # Karpenter discovers this SG by this tag for EC2NodeClass
    "karpenter.sh/discovery" = var.cluster_name
  }
}

############################
# 3. Bastion SG
#    SSH ingress from operator IP only.
############################
resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "Bastion host SSH from operator IP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ingress_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-bastion-sg"
  }
}

############################
# Cross-SG Rules
# Defined separately to avoid circular dependencies.
############################

# Nodes → control plane (443): kubelet registration + API calls
resource "aws_security_group_rule" "nodes_to_control_plane_443" {
  description              = "Karpenter nodes to control plane API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.control_plane.id
  source_security_group_id = aws_security_group.karpenter_node.id
}

# Control plane → nodes (10250): kubectl exec, logs, metrics
resource "aws_security_group_rule" "control_plane_to_nodes_10250" {
  description              = "Control plane to node kubelet"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.karpenter_node.id
  source_security_group_id = aws_security_group.control_plane.id
}

# Control plane → nodes (443): needed for webhooks running on nodes
resource "aws_security_group_rule" "control_plane_to_nodes_443" {
  description              = "Control plane to node webhook port"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.karpenter_node.id
  source_security_group_id = aws_security_group.control_plane.id
}

# Node to node: pods on different nodes need to talk to each other freely
resource "aws_security_group_rule" "node_to_node" {
  description              = "Node to node  all traffic for pod-to-pod communication"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.karpenter_node.id
  source_security_group_id = aws_security_group.karpenter_node.id
}

# Bastion → control plane (443): kubectl from bastion
resource "aws_security_group_rule" "bastion_to_control_plane_443" {
  description              = "Bastion to control plane kubectl access"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.control_plane.id
  source_security_group_id = aws_security_group.bastion.id
}

# Bastion → nodes (22): SSH hop from bastion to nodes for debugging
resource "aws_security_group_rule" "bastion_to_nodes_ssh" {
  description              = "Bastion SSH to Karpenter nodes"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.karpenter_node.id
  source_security_group_id = aws_security_group.bastion.id
}

## metric server 

# resource "aws_security_group_rule" "vpc_to_system_nodes_all" {
#   description       = "Allow all VPC traffic to system nodes"
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"

#   security_group_id = 
#   cidr_blocks       = [var.vpc_cidr]
# }