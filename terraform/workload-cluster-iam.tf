resource "aws_iam_role" "workload_cluster_role" {
  name = "workload-cluster-role-${var.environment}"

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
    Name        = "workload-cluster-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "workload_cluster_attach" {
  role       = aws_iam_role.workload_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

module "workload_cluster_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "workload-cluster-pod-identity"

  associations = {
    workload_app = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "logbeacon"
      service_account = "logbeacon-app"
      role_arn        = aws_iam_role.workload_cluster_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "workload-cluster-pod-identity"
  }
}
