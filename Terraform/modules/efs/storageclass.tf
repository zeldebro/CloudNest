# =========================================================
# StorageClass "efs-sc" - dynamic RWX provisioning via access points.
# Each PVC gets its own isolated EFS directory (efs-ap mode).
# Applied with kubectl_manifest (same provider Karpenter uses).
# =========================================================
resource "kubectl_manifest" "efs_storageclass" {
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = var.storage_class_name
      # The ONLY annotation EFS StorageClasses use: mark efs-sc as the cluster
      # default so PVCs without a storageClassName land on EFS automatically.
      annotations = var.set_default_storage_class ? {
        "storageclass.kubernetes.io/is-default-class" = "true"
      } : {}
    }
    # 'provisioner' (NOT an annotation) is what declares this is EFS.
    # NFS is the underlying protocol the driver uses - never specified here.
    provisioner = "efs.csi.aws.com"
    parameters = {
      provisioningMode = "efs-ap"
      fileSystemId     = aws_efs_file_system.this.id
      directoryPerms   = "700"
      # PVCs land under /dynamic_provisioning/<pvc-name> with a unique access point
      basePath              = "/dynamic_provisioning"
      subPathPattern        = "$${.PVC.namespace}/$${.PVC.name}"
      ensureUniqueDirectory = "true"
    }
    reclaimPolicy     = "Delete"
    volumeBindingMode = "Immediate"
  })

  depends_on = [aws_eks_addon.efs_csi]
}

