resource "random_password" "cloudenest_grafana_admin" {
  length  = 16
  special = true
}

# The secret "container" (no value here)
resource "aws_secretsmanager_secret" "cloudenest_grafana_admin" {
  name = "${var.project}-${var.environment}-grafana-admin"
}

# The secret VALUE (this is the resource that holds secret_string)
resource "aws_secretsmanager_secret_version" "cloudenest_grafana_admin" {
  secret_id     = aws_secretsmanager_secret.cloudenest_grafana_admin.id
  secret_string = random_password.cloudenest_grafana_admin.result
}

# K8s Secret with BOTH keys the chart expects (userKey + passwordKey)
resource "kubernetes_secret" "cloudnest_grafana_admin" {
  metadata {
    name      = "${var.project}-${var.environment}-grafana-admin"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  data = {
    admin-user     = "admin"
    admin-password = random_password.cloudenest_grafana_admin.result
  }

  depends_on = [kubernetes_namespace.monitoring]
}
