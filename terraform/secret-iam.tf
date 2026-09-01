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
#          WORKLOAD CLUSTER - external secrets policy
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


module "workload_es_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "workload-es-pod-identity"

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
#          WORKLOAD CLUSTER - sonarqube cred role
# =============================================================
resource "aws_iam_role" "sonarqube_cred_rwu_role" {
  name = "sonarqube-cred-role-${var.environment}"

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


# =======================================================================
#          WORKLOAD CLUSTER - sonarqube cred read, write, update policy
# =======================================================================
resource "aws_iam_policy" "sonarqube_cred_rwu_policy" {
  name = "sonarqube-cred-rwu-policy-${var.environment}"

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

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:sonarqube-ci-cred*"
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "sonarqube_cred_rwu" {
  role       = aws_iam_role.sonarqube_cred_rwu_role.name
  policy_arn = aws_iam_policy.sonarqube_cred_rwu_policy.arn
}


# =============================================================
#     Sonarqube admin role
# =============================================================
resource "aws_iam_role" "sonarqube_admin_role" {
  name = "sonarqube-admin-role-${var.environment}"

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



resource "aws_iam_policy" "sonarqube_admin_policy" {
  name = "sonarqube-admin-policy-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadAdminPassword"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.sonarqube_admin_password.arn
      },
      {
        Sid    = "ManageCiToken"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.sonarqube_admin_password.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sonarqube_admin" {
  role       = aws_iam_role.sonarqube_admin_role.name
  policy_arn = aws_iam_policy.sonarqube_admin_policy.arn
}


module "sonarqube_cred_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "sonarqube-cred-pod-identity"

  associations = {
    sonarqube_ci_secrets = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "sonarqube"
      service_account = "sonarqube"
      role_arn        = aws_iam_role.sonarqube_cred_rwu_role.arn
    },

    sonarqube_admin = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "sonarqube"
      service_account = "sonarqube"
      role_arn        = aws_iam_role.sonarqube_admin_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "sonarqube-cred-pod-identity"
  }
}


# =============================================================
#      MANAGEMENT CLUSTER - management external secrets role
# =============================================================

resource "aws_iam_role" "management_external_secrets_role" {
  name = "management-es-role-${var.environment}"

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


module "management_es_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "management-es-pod-identity"

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





# =============================================================
#      MANAGEMENT CLUSTER - management github secret
# =============================================================

resource "aws_iam_role" "github_secret_role" {
  name = "github-secret-role-${var.environment}"

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
#     MANAGEMENT CLUSTER - management github secret
# =============================================================
resource "aws_iam_policy" "github_secret_policy" {
  name = "github-secret-secret-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:github-secret*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "github_secret" {
  role       = aws_iam_role.github_secret_role.name
  policy_arn = aws_iam_policy.github_secret_policy.arn
}


module "github_secret_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "github-secret-pod-identity"

  associations = {
    github_secrets = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "github-secret"
      service_account = "github-secret"
      role_arn        = aws_iam_role.github_secret_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "github-secret-pod-identity"
  }
}




# =============================================================
#          LOGBEACON-APP ci - sonarqube cred read policy
# =============================================================
resource "aws_iam_policy" "sonarqube_cred_read" {
  name = "sonarqube-cred-read-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.sonarqube_ci_cred.arn
      }
    ]
  })
}