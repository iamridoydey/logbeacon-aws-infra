data "aws_caller_identity" "current" {}

resource "aws_iam_role" "secret_role" {
  name = "secret-role-${var.environment}"

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
    Name        = "secret-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "secret_manager" {
  name = "logbeacon-secret-manager-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:logbeacon/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secret_policy_attach" {
  role       = aws_iam_role.secret_role.name
  policy_arn = aws_iam_policy.secret_manager.arn
}

module "secret_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "secret-pod-identity"

  associations = {
    secret = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_arn        = aws_iam_role.secret_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "secret-pod-identity"
  }

}