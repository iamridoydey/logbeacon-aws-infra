# =============================================================
#       WORKLOAD CLUSTER - EXTERNAL SECRETS IAM ROLE
# =============================================================

resource "aws_iam_role" "workload_secrets_role" {
  name = "workload-secrets-role-${var.environment}"

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
    Name        = "workload-secrets-role"
    Environment = var.environment
  }
}


# =============================================================
#       WORKLOAD CLUSTER - LOGBEACON SECRETS POLICY
# =============================================================

resource "aws_iam_policy" "logbeacon_secrets_policy" {
  name = "logbeacon-secrets-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadLogbeaconSecrets"
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


# =============================================================
#       WORKLOAD CLUSTER - ATTACH LOGBEACON POLICY
# =============================================================

resource "aws_iam_role_policy_attachment" "logbeacon_secret_attachment" {
  role       = aws_iam_role.workload_secrets_role.name
  policy_arn = aws_iam_policy.logbeacon_secrets_policy.arn
}


# =============================================================
#       WORKLOAD CLUSTER - EXTERNAL SECRETS POD IDENTITY
# =============================================================

module "workload_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "workload-secrets-pod-identity"

  associations = {
    external_secrets = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_arn        = aws_iam_role.workload_secrets_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "workload-secrets-pod-identity"
  }
}


# =============================================================
#       WORKLOAD CLUSTER - SONARQUBE BOOTSTRAP IAM ROLE
# =============================================================

resource "aws_iam_role" "sonarqube_bootstrap_role" {
  name = "sonarqube-bootstrap-role-${var.environment}"

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
    Name        = "sonarqube-bootstrap-role"
    Environment = var.environment
  }
}


# =============================================================
#       SONARQUBE BOOTSTRAP POLICY
# =============================================================

resource "aws_iam_policy" "sonarqube_bootstrap_policy" {
  name = "sonarqube-bootstrap-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadAdminPassword"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = aws_secretsmanager_secret.sonarqube_admin_password.arn
      },

      {
        Sid    = "ManageCiToken"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue"
        ]

        Resource = aws_secretsmanager_secret.sonarqube_ci_cred.arn
      }
    ]
  })
}


# =============================================================
#       ATTACH SONARQUBE BOOTSTRAP POLICY
# =============================================================

resource "aws_iam_role_policy_attachment" "sonarqube_bootstrap_attachment" {
  role       = aws_iam_role.sonarqube_bootstrap_role.name
  policy_arn = aws_iam_policy.sonarqube_bootstrap_policy.arn
}


# =============================================================
#       SONARQUBE BOOTSTRAP POD IDENTITY
# =============================================================

module "sonarqube_bootstrap_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "sonarqube-bootstrap-pod-identity"

  associations = {
    sonarqube_bootstrap = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "sonarqube"
      service_account = "sonarqube"
      role_arn        = aws_iam_role.sonarqube_bootstrap_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "sonarqube-bootstrap-pod-identity"
  }
}


# =============================================================
#       MANAGEMENT CLUSTER - EXTERNAL SECRETS IAM ROLE
# =============================================================

resource "aws_iam_role" "management_secrets_role" {
  name = "management-secrets-role-${var.environment}"

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
    Name        = "management-secrets-role"
    Environment = var.environment
  }
}


# =============================================================
#       MANAGEMENT CLUSTER - CLOUDFLARE SECRET POLICY
# =============================================================

resource "aws_iam_policy" "management_secret_policy" {
  name = "cloudflare-secret-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadCloudflareSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:logbeacon/cloudflare*"
      },
      {
        Sid    = "ReadGithubSecret"
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


# ===========================================================================
# MANAGEMENT CLUSTER - WORKLOAD EKS CREDENTIAL READ POLICY (USED: ci-iam.tf)
# ===========================================================================

resource "aws_iam_policy" "workload_eks_cred_read_policy" {
  name = "workload-eks-cred-read-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadWorkloadEksCredentials"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:workload-eks-cred*"
      }
    ]
  })
}



# =============================================================
#       MANAGEMENT CLUSTER - POLICY ATTACHMENTS
# =============================================================

resource "aws_iam_role_policy_attachment" "management_secret_attachment" {
  role       = aws_iam_role.management_secrets_role.name
  policy_arn = aws_iam_policy.management_secret_policy.arn
}


resource "aws_iam_role_policy_attachment" "workload_eks_cred_read_attachment" {
  role       = aws_iam_role.management_secrets_role.name
  policy_arn = aws_iam_policy.workload_eks_cred_read_policy.arn
}



# =============================================================
#       MANAGEMENT CLUSTER - EXTERNAL SECRETS POD IDENTITY
# =============================================================

module "management_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "management-secrets-pod-identity"

  associations = {
    external_secrets = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_arn        = aws_iam_role.management_secrets_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "management-secrets-pod-identity"
  }
}


# =============================================================
#       LOGBEACON APP CI - SONARQUBE CREDENTIAL READ POLICY
# =============================================================

resource "aws_iam_policy" "sonarqube_cred_read" {
  name = "sonarqube-cred-read-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadSonarqubeCiCredentials"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.sonarqube_ci_cred.arn
      }
    ]
  })
}