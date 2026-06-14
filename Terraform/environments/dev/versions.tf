# Root provider requirements for the dev environment.
# SINGLE source of truth for ALL provider versions across every module.
# Child modules inherit these (only karpenter keeps a minimal kubectl mapping,
# because gavinbunney/kubectl is a non-default source Terraform can't infer).
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

