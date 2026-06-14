# =========================================================
# Promtail DaemonSet - scrapes /var/log/pods on every node, ships to Loki.
# =========================================================
resource "helm_release" "cloudnest_promtail" {
  name       = "${var.project}-${var.environment}-promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  # Verify latest: helm search repo grafana/promtail --versions
  version   = var.promtail_chart_version
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  # Wait for the DaemonSet to roll out; self-heal on failure (auto rollback).
  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  values = [
    templatefile("${path.module}/values/promtail.yaml.tpl", {
      loki_release = helm_release.cloudnest_loki.name
      namespace    = kubernetes_namespace.monitoring.metadata[0].name
    })
  ]

  depends_on = [helm_release.cloudnest_loki]
}