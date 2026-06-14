# MANDATORY: gavinbunney/kubectl is a non-default source Terraform cannot infer,
# so each module using kubectl_manifest must declare the SOURCE here.
# The VERSION is centralized in environments/dev/versions.tf (single source of truth).
terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
