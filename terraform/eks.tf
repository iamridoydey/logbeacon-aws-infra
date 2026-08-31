# =============================================================
#                    WORKLOAD EKS CLUSTER
#                         PRIVATE
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
      resolve_conflicts_on_create = "OVERWRITE"
    }
  }

  # -----------------------------------------------------------
  # EKS API
  # -----------------------------------------------------------

  # Workload cluster is private.
  # ArgoCD in the management cluster accesses the API through
  # the VPC.
  endpoint_public_access  = true
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  # -----------------------------------------------------------
  # NETWORKING
  # -----------------------------------------------------------

  vpc_id = module.vpc.vpc_id

  # Workload nodes are private.
  subnet_ids = module.vpc.private_subnets

  # Control-plane ENIs are also placed in private subnets.
  control_plane_subnet_ids = module.vpc.private_subnets

  # Keep the EKS-managed cluster security group and add our
  # custom security group for additional network rules.
  additional_security_group_ids = [
    module.workload_eks_security_group.id
  ]

  # -----------------------------------------------------------
  # MANAGED NODE GROUP
  # -----------------------------------------------------------

  eks_managed_node_groups = {
    workload = {
      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = [
        "t3.xlarge"
      ]

      min_size     = 2
      desired_size = 3
      max_size     = 4
    }
  }

  # -----------------------------------------------------------
  # EKS ACCESS ENTRIES
  # -----------------------------------------------------------

  access_entries = {
    # ---------------------------------------------------------
    # ArgoCD running in the MANAGEMENT cluster.
    #
    # Allows ArgoCD to authenticate to the workload cluster.
    # ---------------------------------------------------------

    argocd = {
      principal_arn = aws_iam_role.argocd_workload_eks_role.arn

      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    },
    logbeacon_admin = {
      principal_arn = aws_iam_role.logbeacon_admin_role.arn

      policy_associations = {
        argocd = {
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
    Cluster     = "workload"
  }
}


# =============================================================
#                  MANAGEMENT EKS CLUSTER
#                          PUBLIC
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

  # Public API is required for GitHub Actions bootstrap.
  #
  # Private access is also enabled so resources inside the VPC
  # can communicate with the API through the private endpoint.
  endpoint_public_access  = true
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  # -----------------------------------------------------------
  # NETWORKING
  # -----------------------------------------------------------

  vpc_id = module.vpc.vpc_id

  # Management nodes are currently placed in public subnets.
  subnet_ids = module.vpc.public_subnets

  # Control-plane ENIs are placed in public subnets.
  control_plane_subnet_ids = module.vpc.public_subnets

  # Keep the EKS-managed cluster security group and add our
  # custom security group for additional network rules.
  additional_security_group_ids = [
    module.management_eks_security_group.id
  ]

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
      max_size     = 2
    }
  }

  # -----------------------------------------------------------
  # EKS ACCESS ENTRIES
  # -----------------------------------------------------------

  access_entries = {
    # ---------------------------------------------------------
    # GitHub Actions infrastructure bootstrap.
    #
    # Allows the infrastructure CI role to bootstrap and
    # manage the management cluster.
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
    },
    logbeacon_admin = {
      principal_arn = aws_iam_role.logbeacon_admin_role.arn

      policy_associations = {
        argocd = {
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
    Cluster     = "management"
  }
}