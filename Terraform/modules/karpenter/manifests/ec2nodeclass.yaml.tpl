# EC2NodeClass = "HOW to build a node" (AMI, IAM role, where to place it).
# Shared by all NodePools. Karpenter discovers subnets/SGs by the discovery tag.
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${name}
spec:
  # AMI from tfvars (e.g. al2023@latest, bottlerocket@latest)
  amiSelectorTerms:
    - alias: ${ami_alias}

  # Reuse the EKS node role (via the Karpenter instance profile)
  role: ${node_role_name}

  # Discover WHERE to launch by tag (you must tag subnets + SGs!)
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}

  # Encrypt the root volume - size from tfvars
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: ${disk_size}
        volumeType: gp3
        encrypted: true
        deleteOnTermination: true

  # Tags applied to EVERY EC2 instance + volume Karpenter launches.
  # (Terraform default_tags can't reach runtime-launched nodes, so set them here.)
  tags:
    Project: ${project}
    Environment: ${environment}
    ManagedBy: Karpenter
    Name: ${project}-${environment}-karpenter-${name}

