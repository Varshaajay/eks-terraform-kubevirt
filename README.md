# Platform Infrastructure

Infrastructure-as-code and Kubernetes manifests for the `platform-dev` EKS cluster on AWS.

## Repository Layout

```
.
├── terraform/
│   ├── main.tf          # Root module wiring VPC + EKS
│   ├── vpc/             # Custom VPC (subnets, IGW, NAT, route tables)
│   └── eks/             # EKS cluster (managed node groups, addons, IRSA)
├── kubernetes/
│   ├── ns.yaml          # Namespaces (infra, vms, monitoring, gitops, apps)
│   ├── rq.yaml          # ResourceQuotas per namespace
│   ├── sc.yaml          # Default EBS gp3 StorageClass
│   ├── nad.yaml         # Multus NetworkAttachmentDefinition for VM secondary NIC
│   ├── kubevirt-cr.yaml # KubeVirt CR (node placement overrides)
│   └── vm.yaml          # Sample KubeVirt VirtualMachine
└── iam_policy.json      # IAM policy for the AWS Load Balancer Controller
```

## Infrastructure Overview

### VPC (`terraform/vpc/`)

| Resource | Details |
|---|---|
| CIDR | `10.0.0.0/16` |
| Region | `us-east-1` |
| Availability Zones | `us-east-1a`, `us-east-1b` |
| Public subnets | `10.0.1.0/24`, `10.0.2.0/24` |
| Private subnets | `10.0.11.0/24`, `10.0.12.0/24` |
| Egress | Single NAT Gateway in the first public subnet |

### EKS Cluster (`terraform/eks/`)

| Setting | Value |
|---|---|
| Cluster name | `platform-dev` |
| Kubernetes version | `1.33` |
| IRSA | Enabled |
| CloudWatch log retention | 30 days |

**Managed node groups:**

| Group | Instance | Min/Desired/Max | Purpose |
|---|---|---|---|
| `cpu` | `t3.medium` | 2 / 2 / 4 | General workloads |
| `gpu` | `g5.xlarge` | 0 / 0 / 2 | GPU workloads (AL2023 NVIDIA AMI, tainted `nvidia.com/gpu=true:NoSchedule`) |

**Cluster addons:** `coredns`, `kube-proxy`, `vpc-cni`, `eks-pod-identity-agent`

## Kubernetes Manifests

### Namespaces

| Namespace | Purpose |
|---|---|
| `infra` | CSI drivers, CNI, platform controllers |
| `vms` | KubeVirt virtual machines |
| `monitoring` | Prometheus / Grafana / Loki stack |
| `gitops` | ArgoCD / Flux controllers |
| `apps` | General application workloads |

### Storage

A default `ebs-sc` StorageClass is provisioned using the EBS CSI driver (`gp3`, `WaitForFirstConsumer`).

### Virtual Machines (KubeVirt)

KubeVirt is configured to run VMs on worker nodes (node placement affinity stripped from both infra and workload components). VMs use Multus for dual-NIC support:

- **Primary NIC** — pod network (masquerade)
- **Secondary NIC** — macvlan bridge on `eth0`, IPAM range `192.168.100.10–192.168.100.50`

### IAM — AWS Load Balancer Controller

`iam_policy.json` contains the IAM policy required by the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/). Attach it to the controller's IRSA role after the cluster is provisioned.

## Prerequisites

- Terraform >= 1.5
- AWS provider ~> 6.42
- AWS credentials with permissions to create VPC, EKS, IAM, and EC2 resources
- `kubectl` and `aws eks update-kubeconfig` for cluster access

## Usage

### Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name platform-dev
```

### Apply Kubernetes Manifests

```bash
kubectl apply -f kubernetes/ns.yaml
kubectl apply -f kubernetes/rq.yaml
kubectl apply -f kubernetes/sc.yaml
# After installing Multus CNI:
kubectl apply -f kubernetes/nad.yaml
# After installing KubeVirt:
kubectl apply -f kubernetes/kubevirt-cr.yaml
```
