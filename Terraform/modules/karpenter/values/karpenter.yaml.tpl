# Karpenter Helm values - addon-specific.
# Placeholders are filled by templatefile() in main.tf.
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${controller_role_arn}

settings:
  clusterName: ${cluster_name}
  clusterEndpoint: ${cluster_endpoint}
  interruptionQueue: ${interruption_queue}

controller:
  resources:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "1Gi"

