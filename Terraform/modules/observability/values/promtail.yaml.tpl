# grafana/promtail values - ship /var/log/pods to Loki with rich labels.
config:
  clients:
    - url: http://${loki_release}-gateway.${namespace}.svc.cluster.local/loki/api/v1/push
  snippets:
    # Default promtail scrape adds namespace/pod/container; add app + node_name.
    extraRelabelConfigs:
      - source_labels: [__meta_kubernetes_pod_node_name]
        target_label: node_name
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app

