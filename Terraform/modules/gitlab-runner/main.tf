# =========================================================
# GitLab Runner - installed via Helm (consistent with Karpenter/ALB).
# Registers with GitLab using a runner registration token and runs
# CI/CD jobs as pods in the cluster.
# =========================================================

resource "helm_release" "gitlab_runner" {
  name             = "gitlab-runner"
  repository       = "https://charts.gitlab.io"
  chart            = "gitlab-runner"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  # Wait for the runner to be Ready; self-heal on failure (auto rollback) so a
  # retry installs cleanly without a manual `helm uninstall`.
  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  # GitLab instance the runner registers with
  set {
    name  = "gitlabUrl"
    value = var.gitlab_url
  }

  # Authentication token (glrt-...) from Secrets Manager. The MODERN flow:
  # GitLab 16+ removed registration tokens. You create the runner in the GitLab
  # UI (Settings > CI/CD > Runners > New project runner), which returns a
  # `glrt-...` AUTHENTICATION token. Setting `runnerToken` makes the runner use
  # it directly and SKIP the deprecated `register` call (no more 403).
  set_sensitive {
    name  = "runnerToken"
    value = jsondecode(data.aws_secretsmanager_secret_version.runner_token.secret_string)["token"]
  }

  # Let the chart create the RBAC the runner needs to spawn job pods
  set {
    name  = "rbac.create"
    value = "true"
  }

  # ServiceAccount annotated with the IRSA role (keyless AWS access for jobs)
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.runner.arn
  }

  # Concurrent jobs the runner will execute
  set {
    name  = "concurrent"
    value = var.concurrent_jobs
  }
}

