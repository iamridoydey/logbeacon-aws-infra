resource "aws_iam_role" "management_cluster_role" {
  name = "management-cluster-role-${var.environment}"

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
    Name        = "management-cluster-role"
    Environment = var.environment
  }
}

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

resource "aws_iam_role_policy_attachment" "argocd_workload_eks" {
  role       = aws_iam_role.management_cluster_role.name
  policy_arn = aws_iam_policy.argocd_workload_eks.arn
}

module "management_cluster_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "management-cluster-pod-identity"

  associations = {
    management_cluster = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "argocd"
      service_account = "argocd-application-controller"
      role_arn        = aws_iam_role.management_cluster_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "management-cluster-pod-identity"
  }

}
