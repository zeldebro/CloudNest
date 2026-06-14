<div align="center">

# ☁️ CloudNest

### Production-grade **AWS EKS** platform on **Terraform**

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/EKS-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Karpenter](https://img.shields.io/badge/Karpenter-FF9900?style=for-the-badge&logo=amazon&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

![validate](https://img.shields.io/badge/terraform_validate-passing-success?style=flat-square)
![fmt](https://img.shields.io/badge/terraform_fmt-clean-success?style=flat-square)
![OIDC](https://img.shields.io/badge/auth-OIDC_keyless-blue?style=flat-square)

*VPC → EKS → Karpenter (CPU + GPU) → EFS storage → full Observability — shipped via GitHub Actions, no static keys.*

</div>

---

## 📑 Table of Contents
- [🚀 Quick start](#-quick-start)
- [🗂️ Repository layout](#️-repository-layout)
- [⚡ Karpenter vs Node Group](#-karpenter-vs-node-group)
- [🏷️ Tagging](#️-tagging)
- [🧱 Modules](#-modules)
- [🎛️ Feature flags](#️-feature-flags)
- [📊 Access Grafana](#-access-grafana)

---

## 🚀 Quick start

```bash
# 1️⃣  Bootstrap ONCE (local) — creates state backend + GitHub OIDC role
cd bootstrap
terraform init && terraform apply -var-file=bootstrap.tfvars
terraform output -raw bootstrap_bucket_name      # → paste into dev/backend.tf
terraform output -raw github_actions_role_arn    # → GitHub secret AWS_ROLE_ARN

# 2️⃣  GitHub: add secrets + create 'dev' Environment with reviewers
# 3️⃣  Branch → PR (plan) → merge to main → approve → apply 🎉
```

> 🔑 **All config lives in `environments/dev/dev.tfvars`.** Modules expose variables with sensible defaults; you override them **only** in `dev.tfvars`.

---

## 🗂️ Repository layout

```
Terraform/
├── 🥾 bootstrap/          # ONE-TIME: S3+DynamoDB state, OIDC role, KMS (local state)
├── 🌍 environments/dev/   # Root that WIRES modules together + dev.tfvars (single source of values)
└── 🧩 modules/            # Reusable building blocks (one concern each)
```

| Layer | What it owns |
|:--|:--|
| 🥾 **bootstrap** | The things every apply needs *first*: remote state + CI identity |
| 🌍 **environments/dev** | Calls modules, stores state in S3, holds **all values** in `dev.tfvars` |
| 🧩 **modules** | Environment-agnostic, value-free logic |

---

## ⚡ Karpenter vs Node Group

> 🧠 **TL;DR:** *Node Group = always-on **home** for system pods. Karpenter = **on-demand** right-sized nodes for everything else. Neither creates the cluster.*

```
                 aws_eks_cluster  ← creates the Kubernetes control plane (the "brain")
                        │
          ┌─────────────┴──────────────┐
          ▼                            ▼
  🟦 Managed Node Group         🟧 Karpenter
  (always on, min 2)            (scales 0 → N)
  hosts: Karpenter,             launches: app pods,
  CoreDNS, DaemonSets           GPU jobs, bursts
```

| | 🟦 **Managed Node Group** | 🟧 **Karpenter** |
|:--|:--|:--|
| **Role** | Baseline / always-on workers | Dynamic autoscaler |
| **Scaling** | Fixed `min`–`max` (2–3) | **0 → N** from *pending pods* |
| **Instance choice** | You pick the types | **Auto-picks cheapest EC2 that fits** |
| **Hosts** | Karpenter ctrl, CoreDNS, DaemonSets | Apps, GPU, burst workloads |
| **Defined by** | `aws_eks_node_group` | `NodePool` + `EC2NodeClass` CRDs |
| **Idle cost** | Runs 24/7 | Scales to **zero** 💰 |

**Why you need both:** Karpenter can't host *itself* — it needs a stable node to run on. So the small Managed Node Group is its home; Karpenter then provisions everything else on demand and removes nodes when idle.

🔧 **How Karpenter decides:** watches **pending pods** → reads their CPU/mem + constraints → launches the **cheapest, right-sized** EC2 (spot/on-demand) → **bin-packs** → **kills the node** when empty.

---

## 🏷️ Tagging

Every resource is tagged — **no exceptions**:

| Source | Mechanism | ✅ |
|:--|:--|:--:|
| All module resources | provider `default_tags` (`Project`, `Environment`, `ManagedBy`) — inherited (no module declares its own provider) | ✅ |
| Bootstrap resources | bootstrap provider `default_tags` | ✅ |
| Managed node group EC2 | tag propagation to instances/ASG | ✅ |
| **Karpenter EC2 + EBS** | `EC2NodeClass spec.tags` (runtime nodes Terraform can't reach) | ✅ |

---

## 🧩 Modules

<details open>
<summary><b>Core platform</b></summary>

| Module | Files | Purpose |
|:--|:--|:--|
| 🥾 **bootstrap** | `main.tf`, `github-oidc.tf` | State backend (random-suffixed S3 + DynamoDB), KMS, GitHub OIDC role |
| 🌐 **vpc** | `main.tf`, `output.tf` | VPC, public/private subnets, NAT, flow logs |
| 🔒 **security** | `main.tf` | Cluster / node / RDS security groups |
| ☸️ **eks** | `main.tf`, `node-groups.tf`, `iam-*.tf` | Control plane + managed node groups + IAM |
| 🔑 **irsa** | `main.tf`, `s3-reader-role.tf` | OIDC provider + keyless pod roles |
| 🧩 **addons** | `main.tf`, `vpc-cni.tf` | CoreDNS, kube-proxy, VPC CNI (prefix delegation) |
| 🚪 **access** | `iam-roles-groups.tf` | EKS access entries (admin/edit/view) |

</details>

<details open>
<summary><b>Compute & scaling</b></summary>

| Module | Files | Purpose |
|:--|:--|:--|
| 🟧 **karpenter** | `main.tf`, `nodepools.tf`, `iam-controller.tf`, `sqs.tf`, `manifests/*.tpl` | Autoscaler + CPU/GPU NodePools + EC2NodeClass (tagged) |

</details>

<details open>
<summary><b>Storage & data</b></summary>

| Module | Files | Purpose |
|:--|:--|:--|
| 📁 **efs** | `main.tf`, `csi-driver.tf`, `storageclass.tf`, `security.tf` | RWX `efs-sc` storage (KMS, per-AZ mounts, IRSA CSI) |
| 🐘 **rds** | `main.tf`, `kms.tf`, `secret-manager.tf` | Private PostgreSQL + KMS + Secrets Manager |
| 📦 **ecr** | `main.tf`, `repo-policy.tf` | Private image registry |

</details>

<details open>
<summary><b>Networking & edge</b></summary>

| Module | Files | Purpose |
|:--|:--|:--|
| ⚖️ **alb** | `main.tf`, `iam.tf`, `iam-policy.json` | AWS Load Balancer Controller |
| 🛡️ **waf** | `main.tf`, `logging.tf` | Regional Web ACL |
| 🌍 **route53** | `main.tf`, `logging.tf` | Private hosted zone |

</details>

<details open>
<summary><b>Observability & ops</b></summary>

| Module | Files | Purpose |
|:--|:--|:--|
| 📈 **observability** | `prometheus.tf`, `loki*.tf`, `promtail.tf`, `dashboards.tf`, `slo-rules.tf`, `secrets.tf`, `values/*`, `dashboards/*` | Prometheus + Alertmanager + Grafana + Loki + SLOs |
| 📜 **cloudwatch** | `main.tf`, `alb-logs.tf` | Flow-log group + ALB access-log bucket |
| 🔔 **notifications** | `sns.tf`, `sqs.tf`, `alarms.tf`, `budget.tf` | Alerts + cost budget |
| 🦊 **gitlab-runner** | `main.tf`, `iam.tf`, `secrets.tf` | GitLab Runner (Helm) + IRSA |

</details>

---

## 🎛️ Feature flags

Set in `environments/dev/dev.tfvars`:

| Flag | Effect |
|:--|:--|
| `enable_efs = true` | EFS filesystem + CSI + `efs-sc` StorageClass |
| `enable_observability = true` | Full Prometheus/Grafana/Loki/SLO stack |

🎯 **Everything** (chart versions, storage sizes, retention, SLO target) is centralized in `dev.tfvars` — **no module edits required.**

---

## 📊 Access Grafana

```bash
aws eks update-kubeconfig --name cloudnest-dev-eks-cluster --region us-east-1

# admin password (auto-generated → Secrets Manager)
aws secretsmanager get-secret-value \
  --secret-id cloudnest-dev-grafana-admin --query SecretString --output text

# port-forward (free, private, no ALB)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
#  → http://localhost:3000   (admin / password)
```

📜 **Logs:** Grafana → **Explore → Loki** → `{namespace="monitoring"}`.

<div align="center">

---

*🏗️ Built with Terraform · ☁️ Runs on AWS · 🔒 Keyless OIDC · 💰 Scales to zero*

</div>

