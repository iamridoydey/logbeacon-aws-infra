# =============================================================
#                    WORKLOAD EKS CLUSTER
# =============================================================

module "workload_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-workload-cluster"
  kubernetes_version = "1.33"

  # -----------------------------------------------------------
  # EKS ADDONS
  # -----------------------------------------------------------

  addons = {
    coredns = {}

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # -----------------------------------------------------------
  # EKS API
  # -----------------------------------------------------------

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # -----------------------------------------------------------
  # NETWORKING
  # -----------------------------------------------------------

  vpc_id = module.vpc.default_vpc_id

  subnet_ids = module.vpc.public_subnets

  control_plane_subnet_ids = module.vpc.public_subnets

  # -----------------------------------------------------------
  # MANAGED NODE GROUP
  # -----------------------------------------------------------

  eks_managed_node_groups = {
    workload = {
      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = [
        "t3.xlarge"
      ]

      min_size     = 3
      desired_size = 3
      max_size     = 5
    }
  }

  # -----------------------------------------------------------
  # EKS ACCESS ENTRIES
  # -----------------------------------------------------------

  access_entries = {

    # ---------------------------------------------------------
    # ArgoCD running in MANAGEMENT cluster
    # ---------------------------------------------------------

    argocd = {
      principal_arn = aws_iam_role.management_cluster_role.arn

      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # ---------------------------------------------------------
    # GitHub Actions infrastructure bootstrap
    # ---------------------------------------------------------

    infra_bootstrap_ci = {
      principal_arn = module.logbeacon_infra_bootstrap_ci_role.arn

      policy_associations = {
        infra_bootstrap_ci = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Name        = "${var.project_name}-workload-cluster"
  }
}


# =============================================================
#                  MANAGEMENT EKS CLUSTER
# =============================================================

module "management_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-management-cluster"
  kubernetes_version = "1.33"

  # -----------------------------------------------------------
  # EKS ADDONS
  # -----------------------------------------------------------

  addons = {
    coredns = {}

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }

  # -----------------------------------------------------------
  # EKS API
  # -----------------------------------------------------------

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # -----------------------------------------------------------
  # NETWORKING
  # -----------------------------------------------------------

  vpc_id = module.vpc.default_vpc_id

  subnet_ids = module.vpc.public_subnets

  control_plane_subnet_ids = module.vpc.public_subnets

  # -----------------------------------------------------------
  # MANAGED NODE GROUP
  # -----------------------------------------------------------

  eks_managed_node_groups = {
    management = {
      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = [
        "t3.large"
      ]

      min_size     = 2
      desired_size = 2
      max_size     = 3
    }
  }

  # -----------------------------------------------------------
  # EKS ACCESS ENTRIES
  # -----------------------------------------------------------

  access_entries = {

    # ---------------------------------------------------------
    # GitHub Actions infrastructure bootstrap
    # ---------------------------------------------------------

    infra_bootstrap_ci = {
      principal_arn = module.logbeacon_infra_bootstrap_ci_role.arn

      policy_associations = {
        infra_bootstrap_ci = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Name        = "${var.project_name}-management-cluster"
  }
}