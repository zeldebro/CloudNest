# =========================================================
# SLO recording rules + multi-window burn-rate alerts (CNP-018).
# PrometheusRule CRDs applied via kubectl_manifest. The "release" label is what
# the kube-prometheus-stack Prometheus operator uses to discover the rules.
# Assumes an app exposes http_requests_total{code=...}; rules activate when it does.
# =========================================================
locals {
  # Error budget = 1 - SLO target (e.g. 1 - 0.995 = 0.005)
  error_budget = 1 - var.slo_target
}

# --- Recording rules: SLI + burn rates over 1h and 6h windows ---
resource "kubectl_manifest" "slo_recording_rules" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${var.project}-${var.environment}-slo-recording"
      namespace = var.monitoring_namespace
      labels = {
        release = helm_release.cloudnest_prometheus.name
        role    = "slo-rules"
      }
    }
    spec = {
      groups = [{
        name = "slo.recording"
        rules = [
          {
            record = "sli:http_success_rate:5m"
            expr   = "sum(rate(http_requests_total{code!~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"
          },
          {
            record = "slo:burnrate:1h"
            expr   = "(sum(rate(http_requests_total{code=~\"5..\"}[1h])) / sum(rate(http_requests_total[1h]))) / ${local.error_budget}"
          },
          {
            record = "slo:burnrate:6h"
            expr   = "(sum(rate(http_requests_total{code=~\"5..\"}[6h])) / sum(rate(http_requests_total[6h]))) / ${local.error_budget}"
          }
        ]
      }]
    }
  })

  depends_on = [helm_release.cloudnest_prometheus]
}

# --- Burn-rate alerts: fast (page) and slow (warn) ---
resource "kubectl_manifest" "slo_burn_alerts" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${var.project}-${var.environment}-slo-burn"
      namespace = var.monitoring_namespace
      labels = {
        release = helm_release.cloudnest_prometheus.name
        role    = "slo-rules"
      }
    }
    spec = {
      groups = [{
        name = "slo.burnrate.alerts"
        rules = [
          {
            alert = "SLOFastBurn"
            expr  = "slo:burnrate:1h > 14.4"
            for   = "2m"
            labels = {
              severity = "critical"
            }
            annotations = {
              summary     = "Fast error-budget burn (>14.4x)"
              description = "Burning the 30-day error budget >14.4x for 2m - paging #cnp-oncall."
            }
          },
          {
            alert = "SLOSlowBurn"
            expr  = "slo:burnrate:6h > 6"
            for   = "15m"
            labels = {
              severity = "warning"
            }
            annotations = {
              summary     = "Slow error-budget burn (>6x)"
              description = "Burning the 30-day error budget >6x for 15m - notify #cnp-alerts."
            }
          }
        ]
      }]
    }
  })

  depends_on = [helm_release.cloudnest_prometheus]
}