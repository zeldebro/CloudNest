# =========================================================
# Monitoring namespace - created ONCE here so the Grafana secret and the
# Helm release both depend on it (avoids the create_namespace race).
# =========================================================
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

