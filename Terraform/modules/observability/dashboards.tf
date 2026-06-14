# =========================================================
# Custom Grafana dashboards (GitOps).
# Each JSON in dashboards/ becomes a ConfigMap labeled grafana_dashboard=1,
# which the kube-prometheus-stack Grafana sidecar auto-imports.
# Add a dashboard = drop a new .json file here. No code change needed.
# =========================================================
resource "kubernetes_config_map" "grafana_dashboards" {
  for_each = fileset("${path.module}/dashboards", "*.json")

  metadata {
    name      = "grafana-dashboard-${trimsuffix(each.value, ".json")}"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    (each.value) = file("${path.module}/dashboards/${each.value}")
  }

  depends_on = [kubernetes_namespace.monitoring]
}