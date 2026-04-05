############################
# Namespace
############################
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

############################
# ArgoCD Helm install
############################
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  create_namespace = false

  cleanup_on_fail = true
  atomic          = true
  wait            = true
  timeout         = 600

values = [<<EOF
global:
  tolerations:
    - key: "CriticalAddonsOnly"
      operator: "Exists"
      effect: "NoSchedule"

  nodeSelector:
    role: system

server:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"

EOF
]
  depends_on = [kubernetes_namespace.argocd]
}

############################
# Karpenter Namespace
############################
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

############################
# Karpenter CRDs 
############################
resource "helm_release" "karpenter_crds" {
  name             = "karpenter-crd"
  namespace        = kubernetes_namespace.karpenter.metadata[0].name
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter-crd"
  version          = "1.10.0"
  create_namespace = false
  
  wait = true
  timeout = 120
}

############################
# Karpenter Controller
############################
resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = kubernetes_namespace.karpenter.metadata[0].name
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.0"
  create_namespace = false
  
  set {
    name  = "settings.clusterName"
    value = var.cluster_name  
  }
  
  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }
  
  set {
    name  = "settings.interruptionQueue"
    value = var.interruption_queue
  }
  
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.karpenter_controller_role_arn
  }
  
  set {
    name  = "controller.resources.requests.cpu"
    value = "200m"
  }
  
  set {
    name  = "controller.resources.requests.memory"
    value = "512Mi"
  }
  
  wait = true
  timeout = 300
  depends_on = [helm_release.karpenter_crds]
}

