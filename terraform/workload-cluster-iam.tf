# =============================================================
#          LOGBEACON APP -> ECR IAM ROLE
# =============================================================

resource "aws_iam_role" "logbeacon_app_ecr_role" {
  name = "logbeacon-app-ecr-role-${var.environment}"

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
    Name        = "logbeacon-app-ecr-role"
    Environment = var.environment
  }
}


# =============================================================
#          ALLOW LOGBEACON APP TO READ ECR
# =============================================================

resource "aws_iam_role_policy_attachment" "logbeacon_app_ecr" {
  role       = aws_iam_role.logbeacon_app_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# =============================================================
#       WORKLOAD EKS -> LOGBEACON APP POD IDENTITY
# =============================================================

module "logbeacon_app_ecr_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "logbeacon-app-ecr-pod-identity"

  associations = {
    logbeacon_app = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "logbeacon"
      service_account = "logbeacon"
      role_arn        = aws_iam_role.logbeacon_app_ecr_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "logbeacon-app-ecr-pod-identity"
  }
}