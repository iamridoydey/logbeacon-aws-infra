# =============================================================
#          WORKLOAD CLUSTER - external secrets role
# =============================================================
resource "aws_iam_role" "workload_external_secrets_role" {
  name = "workload-external-secrets-role-${var.environment}"

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
    Name        = "workload-external-secrets-role"
    Environment = var.environment
  }
}


# =============================================================
#          WORKLOAD CLUSTER - external secrets
# =============================================================
resource "aws_iam_policy" "workload_external_secrets" {
  name = "workload-external-secrets-${var.environment}"

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


resource "aws_iam_role_policy_attachment" "workload_external_secrets" {
  role       = aws_iam_role.workload_external_secrets_role.name
  policy_arn = aws_iam_policy.workload_external_secrets.arn
}


module "workload_external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "workload-external-secrets-pod-identity"

  associations = {
    external_secrets = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_arn        = aws_iam_role.workload_external_secrets_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "workload-external-secrets-pod-identity"
  }
}


# =============================================================
#      MANAGEMENT CLUSTER - management external secrets role
# =============================================================

resource "aws_iam_role" "management_external_secrets_role" {
  name = "management-external-secrets-role-${var.environment}"

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
    Name        = "management-external-secrets-role"
    Environment = var.environment
  }
}

# =============================================================
#     MANAGEMENT CLUSTER - management external secrets
# =============================================================
resource "aws_iam_policy" "management_external_secrets" {
  name = "management-external-secrets-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:logbeacon/cloudflare*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "management_external_secrets" {
  role       = aws_iam_role.management_external_secrets_role.name
  policy_arn = aws_iam_policy.management_external_secrets.arn
}


module "management_external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "management-external-secrets-pod-identity"

  associations = {
    external_secrets = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_arn        = aws_iam_role.management_external_secrets_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "management-external-secrets-pod-identity"
  }
}


# =============================================================
#     workload cluster credentials read write policy
# =============================================================
resource "aws_iam_policy" "workload_cred_read_write" {
  name = "workload-cred-read-write-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
        ]

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:workload-eks-cred*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "workload_eks_cred" {
  role       = aws_iam_role.management_external_secrets_role.name
  policy_arn = aws_iam_policy.workload_cred_read_write.arn
}