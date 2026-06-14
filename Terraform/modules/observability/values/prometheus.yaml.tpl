# kube-prometheus-stack values - persistence on EFS (efs-sc) + Grafana admin from K8s secret.
# Rendered by templatefile() in prometheus.tf.

# --- Prometheus TSDB persistence (efs-sc, 50Gi) ---
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ${storage_class}
          accessModes: ["ReadWriteMany"]
          resources:
            requests:
              storage: ${prometheus_storage_size}

# --- Grafana: persistence + admin creds from the existing K8s secret ---
grafana:
  defaultDashboardsEnabled: true   # built-ins: Cluster Overview, Node Detail, Namespace Resource
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard     # imports any ConfigMap with this label
      searchNamespace: ALL
  persistence:
    enabled: true
    storageClassName: ${storage_class}
    accessModes: ["ReadWriteMany"]
    size: ${grafana_storage_size}
  admin:
    existingSecret: ${grafana_secret_name}
    userKey: admin-user
    passwordKey: admin-password

# --- Alertmanager persistence (light) ---
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: ${storage_class}
          accessModes: ["ReadWriteMany"]
          resources:
            requests:
              storage: ${alertmanager_storage_size}
