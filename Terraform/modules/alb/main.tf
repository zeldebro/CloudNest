# =========================================================
# AWS Load Balancer Controller (installed via Helm)
# Watches Ingress objects and provisions ALBs automatically.
# The ServiceAccount is annotated with the IRSA role created in iam.tf.
# =========================================================
resource "helm_release" "controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.chart_version

  # Block until the controller pods are actually Ready. Its mutating webhook
  # intercepts ALL Service creation cluster-wide, so anything that depends on
  # this module must not proceed until the webhook has live endpoints.
  wait    = true
  timeout = 600

  # Self-healing installs: if the release fails (e.g. timeout), atomic rolls it
  # back (uninstalls) instead of leaving a "failed" release behind, so the next
  # apply does a clean install - no manual `helm uninstall` needed.
  atomic          = true
  cleanup_on_fail = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.controller.arn
  }
}

