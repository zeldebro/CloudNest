# MANDATORY: gavinbunney/kubectl is a non-default source Terraform cannot infer.
# Only the SOURCE is declared here; the VERSION is centralized in environments/dev/versions.tf.
terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
