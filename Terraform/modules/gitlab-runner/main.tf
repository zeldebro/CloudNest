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

  # GitLab instance the runner registers with
  set {
    name  = "gitlabUrl"
    value = var.gitlab_url
  }

  # Registration token - read from Secrets Manager (not from env/CI)
  set_sensitive {
    name  = "runnerRegistrationToken"
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

