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

      resolve_conflicts_on_create = "OVERWRITE"
    }
  }


  # -----------------------------------------------------------
  # EKS API ENDPOINT
  # -----------------------------------------------------------

  # Workload Kubernetes API is accessible only through
  # the VPC/private endpoint.
  #
  # Argo CD runs inside the management cluster in the same VPC,
  # so it can reach the workload EKS API privately.
  #
  # The admin EC2 instance also reaches the cluster through
  # the private endpoint.
  endpoint_public_access  = false
  endpoint_private_access = true

  # Explicit access entries are defined below.
  enable_cluster_creator_admin_permissions = false


  # -----------------------------------------------------------
  # NETWORKING
  # -----------------------------------------------------------

  vpc_id = module.vpc.vpc_id

  # Worker nodes run in private subnets.
  subnet_ids = module.vpc.private_subnets

  # EKS control-plane ENIs are attached to private subnets.
  control_plane_subnet_ids = module.vpc.private_subnets

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
        "t3.large"
      ]

      min_size     = 2
      desired_size = 2
      max_size     = 4
    }
  }


  # -----------------------------------------------------------
  # EKS ACCESS ENTRIES
  # -----------------------------------------------------------

  access_entries = {

    # ---------------------------------------------------------
    # ARGO CD
    #
    # This is the IAM role Argo CD uses when authenticating
    # to the workload EKS cluster.
    # ---------------------------------------------------------

    argocd = {
      principal_arn = aws_iam_role.argocd_workload_eks_role.arn

      policy_associations = {
        argocd_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }


    # ---------------------------------------------------------
    # ADMIN EC2
    #
    # Commands executed through the private admin instance use
    # the EC2 instance IAM role.
    # ---------------------------------------------------------

    logbeacon_admin = {
      principal_arn = aws_iam_role.logbeacon_admin_role.arn

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }


  # -----------------------------------------------------------
  # TAGS
  # -----------------------------------------------------------

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-workload-cluster"
      Cluster = "workload"
    }
  )
}


# =============================================================
#                   MANAGEMENT EKS CLUSTER
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
  # EKS API ENDPOINT
  # -----------------------------------------------------------

  # GitHub Actions does not connect directly to the Kubernetes
  # API in this architecture.
  #
  # GitHub Actions -> SSM -> Admin EC2 -> Management EKS
  #
  # Therefore the management EKS API can also remain private.
  endpoint_public_access  = false
  endpoint_private_access = true

  # Access is controlled explicitly through EKS access entries.
  enable_cluster_creator_admin_permissions = false


  # -----------------------------------------------------------
  # NETWORKING
  # -----------------------------------------------------------

  vpc_id = module.vpc.vpc_id

  # Management worker nodes run in private subnets.
  subnet_ids = module.vpc.private_subnets

  # EKS control-plane ENIs are attached to private subnets.
  control_plane_subnet_ids = module.vpc.private_subnets

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
        "t3.medium"
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
    # ADMIN EC2
    #
    # GitHub CI reaches this instance through SSM.
    # Kubernetes commands executed on this instance use this
    # IAM role.
    # ---------------------------------------------------------

    logbeacon_admin = {
      principal_arn = aws_iam_role.logbeacon_admin_role.arn

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }


  # -----------------------------------------------------------
  # TAGS
  # -----------------------------------------------------------

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-management-cluster"
      Cluster = "management"
    }
  )
}