# CloudNest — Architecture (architect.md)

A production-grade AWS EKS platform built with Terraform, deployed through GitHub Actions
(OIDC, no static keys), with shared EFS storage and a full observability stack
(Prometheus, Alertmanager, Grafana, Loki/Promtail, SLOs).

---

## 1. High-level overview

```
Developer ──PR──► GitHub Actions (OIDC) ──assume role──► AWS
                       │  validate → plan → (merge) → apply
                       ▼
        ┌──────────────────────────────────────────────┐
        │                AWS Account (dev)              │
        │                                               │
        │   VPC (public/private subnets, NAT, flow logs)│
        │        └── EKS cluster (control plane)        │
        │              ├── Managed node group (system)  │
        │              ├── Karpenter (CPU + GPU, 0→N)    │
        │              ├── EFS CSI  → efs-sc (RWX PVCs)  │
        │              └── Observability namespace       │
        │   S3 (TF state, Loki logs)  DynamoDB (lock)   │
        │   ECR, RDS, WAF, Route53, Secrets Manager, KMS │
        └──────────────────────────────────────────────┘
```

---

## 2. Delivery pipeline (GitHub Actions)

| Stage | Trigger | Action |
|-------|---------|--------|
| Validate & Scan | PR + push | `fmt -check`, `validate`, TFLint, Trivy |
| Plan | PR + push | `terraform plan`, saved as artifact, posted as PR comment |
| Apply | push to `main` | downloads the **reviewed** plan, waits for `dev` environment approval, `terraform apply` |

- **Auth:** GitHub OIDC → assumes the `cloudnest-dev-github-actions` IAM role (created in `bootstrap`). No long-lived AWS keys.
- **State:** S3 bucket + DynamoDB lock table (created in `bootstrap`, consumed by `environments/dev/backend.tf`).

---

## 3. Terraform module map

| Layer | Module | Purpose |
|-------|--------|---------|
| Bootstrap | `bootstrap` | OIDC provider + GitHub Actions role, S3 state bucket, DynamoDB lock, KMS |
| Network | `vpc`, `security`, `route53` | VPC/subnets/NAT/flow logs, security groups, private DNS |
| Compute | `eks`, `karpenter`, `addons` | Control plane, system node group, autoscaling (CPU + GPU scale-from-zero), core add-ons |
| Identity | `irsa`, `access` | OIDC IRSA roles (keyless pods), EKS access entries |
| Storage | `efs`, `rds`, `ecr` | EFS RWX (`efs-sc`), PostgreSQL, container registry |
| Edge/Sec | `alb`, `waf` | AWS Load Balancer Controller, regional Web ACL |
| Ops | `cloudwatch`, `notifications`, `observability` | Flow-log group, SNS/budget alerts, monitoring stack |

---

## 4. Storage — EFS (`efs-sc`)

```
Pod ──PVC (storageClassName: efs-sc, RWX)──► EFS CSI driver ──► EFS filesystem
                                                              ├─ mount target AZ-a
                                                              ├─ mount target AZ-b
                                                              └─ mount target AZ-c   (NFS 2049, node SG only)
```
- KMS-encrypted, one mount target per AZ, access-point dynamic provisioning.
- Feature-flagged: `enable_efs = true`.

---

## 5. Observability (CNP-015 → CNP-018)

```
                         ┌─────────────── monitoring namespace ───────────────┐
  app /metrics ──scrape──► Prometheus ──► Alertmanager ──(routes)──► Slack receivers
                         │     │                 warning → #cnp-alerts          │
                         │     │                 critical → #cnp-oncall         │
                         │     ▼                                                │
                         │  Grafana ◄── dashboards (ConfigMaps, sidecar import) │
                         │     ▲                                                │
  pods /var/log ─Promtail┼─────┘ logs ──► Loki ──► S3 (IRSA, no keys)           │
                         │                                                      │
  SLO PrometheusRules: sli:http_success_rate:5m + burn-rate (1h/6h) alerts      │
                         └──────────────────────────────────────────────────────┘
```

| Task | What | Storage |
|------|------|---------|
| CNP-015 | Prometheus + Alertmanager (group_wait 30s, group_interval 5m, critical repeat 1h, cluster-down inhibit) | efs-sc 50Gi / 5Gi |
| CNP-016 | Grafana: 3 built-in + 2 custom dashboards, sidecar auto-import, GitOps JSON | efs-sc 10Gi |
| CNP-017 | Loki (S3 via IRSA) + Promtail DaemonSet (labels: namespace/pod/container/app/node_name) | S3 + efs-sc |
| CNP-018 | SLO 99.5%/30d/216-min budget, fast-burn >14.4×/2m (critical), slow-burn >6×/15m (warning) | — |

- **Secrets:** Grafana admin password = `random_password` → Secrets Manager → K8s secret (`existingSecret`). Slack webhook = Secrets Manager (placeholder until provided).
- **All tunables** (chart versions, sizes, retention, SLO target) are set in `environments/dev/dev.tfvars`.

---

## 6. Security model

- **Keyless everywhere:** GitHub→AWS via OIDC; pods→AWS via IRSA (Loki S3, ALB, Karpenter, EFS CSI).
- **Encryption:** KMS for EFS, RDS, S3, Secrets Manager.
- **Network:** private subnets for nodes/RDS/EFS; EFS NFS limited to the node SG; WAF on the ALB.
- **Least privilege:** scoped IRSA trust policies per ServiceAccount.

---

## 7. Feature flags (in `dev.tfvars`)

| Flag | Effect |
|------|--------|
| `enable_efs` | Create EFS + CSI + `efs-sc` |
| `enable_observability` | Deploy the full monitoring stack |

---

## 8. How to deploy

1. `bootstrap` once (local) → get OIDC role ARN, set `AWS_ROLE_ARN` secret.
2. Create the `dev` GitHub Environment with required reviewers.
3. Branch → PR (plan posted) → merge to `main` → approve → apply.

