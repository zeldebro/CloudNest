output "vpc_cni_version" {
  description = "Installed VPC CNI addon version"
  value       = aws_eks_addon.vpc_cni.addon_version
}

output "coredns_version" {
  description = "Installed CoreDNS addon version"
  value       = aws_eks_addon.coredns.addon_version
}

output "kube_proxy_version" {
  description = "Installed kube-proxy addon version"
  value       = aws_eks_addon.kube_proxy.addon_version
}

