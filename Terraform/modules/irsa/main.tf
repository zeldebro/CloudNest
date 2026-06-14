# Step 1: fetch the OIDC issuer's TLS certificate (to get its thumbprint).
# IMPORTANT: the issuer URL comes FROM the cluster - never hand-built.
data "tls_certificate" "eks" {
  url = var.oidc_issuer_url
}

# Step 2: register the cluster OIDC issuer as an IAM Identity Provider
resource "aws_iam_openid_connect_provider" "eks" {
  url             = var.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.project}-${var.environment}-eks-oidc"
  }
}