# =============================================================
#       WORKLOAD CLUSTER - LOGBEACON SECRETS POLICY
# =============================================================

resource "aws_iam_policy" "logbeacon_secrets_policy" {
  name = "logbeacon-secrets-policy"

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

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-secrets-policy"
    }
  )
}


# =============================================================
#       WORKLOAD CLUSTER - EXTERNAL SECRETS POD IDENTITY
# =============================================================

module "workload_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name            = "workload-secrets-role"
  use_name_prefix = false

  trust_policy_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-arn"
      values   = [module.workload_eks.cluster_arn]
    },
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["external-secrets"]
    },
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["external-secrets"]
    }
  ]

  additional_policy_arns = {
    LogbeaconSecretsPolicy = aws_iam_policy.logbeacon_secrets_policy.arn
  }

  associations = {
    external_secrets = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "workload-secrets-role"
    }
  )
}


# =============================================================
#       SONARQUBE BOOTSTRAP POLICY
# =============================================================

resource "aws_iam_policy" "sonarqube_bootstrap_policy" {
  name = "sonarqube-bootstrap-policy"

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

  tags = merge(
    local.common_tags,
    {
      Name = "sonarqube-bootstrap-policy"
    }
  )
}


# =============================================================
#       SONARQUBE BOOTSTRAP POD IDENTITY
# =============================================================

module "sonarqube_bootstrap_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name            = "sonarqube-bootstrap-role"
  use_name_prefix = false

  trust_policy_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-arn"
      values   = [module.workload_eks.cluster_arn]
    },
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["sonarqube"]
    },
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["sonarqube"]
    }
  ]

  additional_policy_arns = {
    SonarqubeBootstrapPolicy = aws_iam_policy.sonarqube_bootstrap_policy.arn
  }

  associations = {
    sonarqube_bootstrap = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "sonarqube"
      service_account = "sonarqube"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "sonarqube-bootstrap-role"
    }
  )
}


# =============================================================
#       MANAGEMENT CLUSTER - SECRETS POLICY
# =============================================================

resource "aws_iam_policy" "management_secret_policy" {
  name = "management-secrets-policy"

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

  tags = merge(
    local.common_tags,
    {
      Name = "management-secrets-policy"
    }
  )
}


# =============================================================
#       MANAGEMENT CLUSTER - WORKLOAD EKS CREDENTIAL READ POLICY
# =============================================================

resource "aws_iam_policy" "workload_eks_cred_read_policy" {
  name = "workload-eks-cred-read-policy"

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

  tags = merge(
    local.common_tags,
    {
      Name = "workload-eks-cred-read-policy"
    }
  )
}


# =============================================================
#       MANAGEMENT CLUSTER - EXTERNAL SECRETS POD IDENTITY
# =============================================================

module "management_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name            = "management-secrets-role"
  use_name_prefix = false

  trust_policy_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-arn"
      values   = [module.management_eks.cluster_arn]
    },
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["external-secrets"]
    },
    {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["external-secrets"]
    }
  ]

  additional_policy_arns = {
    ManagementSecretsPolicy   = aws_iam_policy.management_secret_policy.arn
    WorkloadEksCredReadPolicy = aws_iam_policy.workload_eks_cred_read_policy.arn
  }

  associations = {
    external_secrets = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "management-secrets-role"
    }
  )
}


# =============================================================
#       LOGBEACON APP CI - SONARQUBE CREDENTIAL READ POLICY
# =============================================================

resource "aws_iam_policy" "sonarqube_cred_read" {
  name = "sonarqube-cred-read"

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

  tags = merge(
    local.common_tags,
    {
      Name = "sonarqube-cred-read"
    }
  )
}