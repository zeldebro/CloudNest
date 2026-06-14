# Alertmanager routing / grouping / inhibition for kube-prometheus-stack.
# Merged with prometheus.yaml.tpl by Helm (deep-merge of the alertmanager key).
# Slack receivers are left as commented placeholders - add slack_configs once
# you have a webhook; routing/grouping/inhibit work without it.
alertmanager:
  config:
    global:
      resolve_timeout: 5m

    # Top-level route = defaults every alert inherits unless a child route matches.
    route:
      group_by: ["alertname", "namespace"]
      group_wait: 30s        # batch the first alerts of a new group
      group_interval: 5m     # wait before sending NEW alerts added to a group
      repeat_interval: 4h    # default re-send cadence for still-firing alerts
      receiver: "null"       # default sink (no Slack yet)
      routes:
        # critical -> #cnp-oncall, remind every 1h
        - matchers:
            - severity = "critical"
          receiver: "critical"
          repeat_interval: 1h
        # warning -> #cnp-alerts
        - matchers:
            - severity = "warning"
          receiver: "warning"

    receivers:
      - name: "null"
      - name: "warning"
        # slack_configs:
        #   - api_url_file: /etc/alertmanager/secrets/slack/webhook-url
        #     channel: "#cnp-alerts"
        #     send_resolved: true
      - name: "critical"
        # slack_configs:
        #   - api_url_file: /etc/alertmanager/secrets/slack/webhook-url
        #     channel: "#cnp-oncall"
        #     send_resolved: true

    # cluster-down silences all other alerts for the same cluster (avoids alert storms)
    inhibit_rules:
      - source_matchers:
          - alertname = "ClusterDown"
        target_matchers:
          - severity =~ "warning|critical"
        equal: ["cluster"]

