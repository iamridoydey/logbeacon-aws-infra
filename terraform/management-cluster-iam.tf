# =============================================================
#              ARGOCD -> WORKLOAD EKS IAM ROLE
# =============================================================

resource "aws_iam_role" "argocd_workload_eks_role" {
  name = "argocd-workload-eks-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name        = "argocd-workload-eks-role"
    Environment = var.environment
  }
}


# =============================================================
#         ALLOW ARGOCD TO DESCRIBE WORKLOAD EKS
# =============================================================

resource "aws_iam_policy" "argocd_workload_eks" {
  name = "argocd-workload-eks-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = module.workload_eks.cluster_arn
      }
    ]
  })
}


# =============================================================
#          ATTACH POLICY TO ARGOCD IAM ROLE
# =============================================================

resource "aws_iam_role_policy_attachment" "argocd_workload_eks" {
  role       = aws_iam_role.argocd_workload_eks_role.name
  policy_arn = aws_iam_policy.argocd_workload_eks.arn
}


# =============================================================
#       MANAGEMENT EKS -> ARGOCD POD IDENTITY
# =============================================================

module "argocd_workload_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "argocd-workload-eks-pod-identity"

  associations = {
    argocd = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "argocd"
      service_account = "argocd-application-controller"
      role_arn        = aws_iam_role.argocd_workload_eks_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "argocd-workload-eks-pod-identity"
  }
}