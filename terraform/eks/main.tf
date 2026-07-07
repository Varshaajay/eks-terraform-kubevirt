module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true

  cloudwatch_log_group_retention_in_days = 30

  addons = {
    coredns = {}
    kube-proxy = {}
    eks-pod-identity-agent = {}
    vpc-cni = {}
  }

  eks_managed_node_groups = {

    cpu = {
      instance_types = ["t3.medium"]

      min_size     = 2
      desired_size = 2
      max_size     = 4

      capacity_type = "ON_DEMAND"

      labels = {
        workload = "general"
      }
    }

    gpu = {
      instance_types = ["g5.xlarge"]

      min_size     = 0
      desired_size = 0
      max_size     = 2

      capacity_type = "ON_DEMAND"

      ami_type = "AL2023_x86_64_NVIDIA"

      labels = {
        workload = "gpu"
      }

      taints = {
        gpu = {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  tags = {
    Project = "PlatformEngineering"
  }
}
