# NodePool "gpu" = GPU workloads only. Tainted so normal pods stay away.
# Scales from zero - $0 when no GPU pods are pending.
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: gpu
spec:
  template:
    metadata:
      labels:
        workload: gpu
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${node_class_name}
      # Taint: ONLY pods tolerating nvidia.com/gpu land here
      taints:
        - key: nvidia.com/gpu
          value: "true"
          effect: NoSchedule
      requirements:
        # Capacity types from tfvars (e.g. ["spot","on-demand"] or ["on-demand"])
        - key: karpenter.sh/capacity-type
          operator: In
          values: ${jsonencode(capacity_types)}
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        # GPU instance families from tfvars (e.g. ["g5","g4dn"])
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: ${jsonencode(instance_families)}
      expireAfter: 720h

  # 🛑 GPU cost guardrail - from tfvars
  limits:
    nvidia.com/gpu: "${gpu_limit}"

  # Remove GPU nodes quickly when empty (expensive to leave idle)
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 60s

