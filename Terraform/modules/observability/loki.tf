# =========================================================
# Loki (single-binary) backed by S3 via IRSA. grafana/loki chart.
# =========================================================
resource "helm_release" "cloudnest_loki" {
  name       = "${var.project}-${var.environment}-loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  # Verify latest: helm search repo grafana/loki --versions
  version   = var.loki_chart_version
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/loki.yaml.tpl", {
      bucket            = aws_s3_bucket.cloudnest_loki_s3_bucket.id
      region            = var.region
      role_arn          = aws_iam_role.loki.arn
      storage_class     = var.storage_class
      loki_storage_size = var.loki_storage_size
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    aws_iam_role_policy_attachment.loki_s3
  ]
}