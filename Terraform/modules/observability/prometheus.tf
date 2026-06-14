resource "helm_release" "cloudnest_prometheus" {
  name       = "${var.project}-${var.environment}-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  # Verify the latest with:
  #   helm search repo prometheus-community/kube-prometheus-stack --versions
  version   = var.chart_version
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  # efs-sc persistence (Prometheus 50Gi + Grafana) and Grafana admin.existingSecret
  values = [
    templatefile("${path.module}/values/prometheus.yaml.tpl", {
      storage_class             = var.storage_class
      prometheus_storage_size   = var.prometheus_storage_size
      grafana_storage_size      = var.grafana_storage_size
      alertmanager_storage_size = var.alertmanager_storage_size
      grafana_secret_name       = kubernetes_secret.cloudnest_grafana_admin.metadata[0].name
    }),
    # Alertmanager routing/grouping/inhibit (deep-merged by Helm)
    file("${path.module}/values/alertmanager.yaml.tpl")
  ]

  depends_on = [kubernetes_namespace.monitoring]
}
