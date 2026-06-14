# NodePool "general" = CPU workloads on Spot, right-sized by Karpenter.
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: general
spec:
  template:
    metadata:
      labels:
        workload: general
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${node_class_name}
      requirements:
        # Capacity types from tfvars (e.g. ["spot","on-demand"])
        - key: karpenter.sh/capacity-type
          operator: In
          values: ${jsonencode(capacity_types)}
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        # Instance families from tfvars (e.g. ["c","m","r"])
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ${jsonencode(instance_categories)}
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]
      # Recycle nodes after 30 days (security + patching)
      expireAfter: 720h

  # 🛑 THE COST GUARDRAIL - from tfvars
  limits:
    cpu: "${cpu_limit}"
    memory: ${memory_limit}

  # Bin-pack: remove/replace underused nodes to save money
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s

