# grafana/loki single-binary values - S3 storage via IRSA, EFS for the small WAL/cache.
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: s3
    bucketNames:
      chunks: ${bucket}
      ruler: ${bucket}
      admin: ${bucket}
    s3:
      region: ${region}
  schemaConfig:
    configs:
      - from: "2024-04-01"
        store: tsdb
        object_store: s3
        schema: v13
        index:
          prefix: loki_index_
          period: 24h

# Single-binary mode (dev-friendly); disable the scalable components
deploymentMode: SingleBinary
singleBinary:
  replicas: 1
  persistence:
    enabled: true
    storageClass: ${storage_class}
    accessModes: ["ReadWriteMany"]
    size: ${loki_storage_size}
backend:  { replicas: 0 }
read:     { replicas: 0 }
write:    { replicas: 0 }
chunksCache:  { enabled: false }
resultsCache: { enabled: false }

gateway:
  enabled: true

# IRSA: bind the loki-sa ServiceAccount to the S3 role (keyless)
serviceAccount:
  create: true
  name: loki-sa
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}

