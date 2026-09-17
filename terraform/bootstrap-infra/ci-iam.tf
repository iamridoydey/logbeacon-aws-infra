# =============================================================
# LOGBEACON APP REPO CI ROLE
# =============================================================

module "logbeacon_app_ci_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.1"

  name = "logbeacon-app-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:${var.github_username}/logbeacon-app:ref:refs/heads/main"
  ]

  policies = {
    EcrReadWrite      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    SonarqubeCredRead = aws_iam_policy.sonarqube_cred_read_policy.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-app-ci-role"
    }
  )
}


# =============================================================
# LOGBEACON INFRA REPO CI ROLES
# =============================================================

module "logbeacon_infra_bootstrap_pr_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.1"

  name = "logbeacon-infra-bootstrap-pr-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:${var.github_username}/logbeacon-aws-infra:pull_request"
  ]

  policies = {
    TfStateAccess = aws_iam_policy.terraform_state_access.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-infra-bootstrap-pr-role"
    }
  )
}

module "logbeacon_infra_bootstrap_ci_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.1"

  name = "logbeacon-infra-bootstrap-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:ref:refs/heads/main"
  ]

  policies = {
    TfStateAccess             = aws_iam_policy.terraform_state_access.arn
    WorkloadEksCredReadPolicy = aws_iam_policy.workload_eks_cred_read_policy.arn
    SsmAdminHostAccess        = aws_iam_policy.infra_ci_ssm_access.arn
    SsmAdminS3Access          = aws_iam_policy.ansible_ssm_transfer.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-infra-bootstrap-ci-role"
    }
  )
}


# =============================================================
# INFRA CI - TERRAFORM STATE S3 ACCESS POLICY
# =============================================================

resource "aws_iam_policy" "terraform_state_access" {
  name = "logbeacon-terraform-state-access"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "TerraformStateS3Access"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::logbeacon-state-file",
          "arn:aws:s3:::logbeacon-state-file/*"
        ]
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-terraform-state-access"
    }
  )
}


# =============================================================
# WORKLOAD EKS CREDENTIAL READ POLICY
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
# SONARQUBE CI CREDENTIAL READ POLICY
# =============================================================

resource "aws_iam_policy" "sonarqube_cred_read_policy" {
  name = "sonarqube-cred-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadSonarqubeCiCredentials"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:sonarqube-ci-cred*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "sonarqube-cred-read-policy"
    }
  )
}


# =============================================================
# INFRA CI - SSM ACCESS POLICY (ADMIN HOST)
# =============================================================
# NOTE: requires aws_instance.logbeacon_admin (in main-infra/ec2.tf)
# to carry the tag Role = "logbeacon-admin" — confirm this before
# relying on this policy.

resource "aws_iam_policy" "infra_ci_ssm_access" {
  name = "infra-ci-ssm-access"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManageAdminHostThroughSsm"
        Effect = "Allow"

        Action = [
          "ssm:StartSession",
          "ssm:SendCommand",
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:ResourceTag/Role" = "logbeacon-admin"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "infra-ci-ssm-access"
    }
  )
}


# =============================================================
# ANSIBLE SSM S3 TRANSFER POLICY
# =============================================================
# NOTE: bucket name below must exactly match the `bucket = "..."`
# value on aws_s3_bucket.ansible_ssm_transfer in main-infra —
# confirm and correct if it differs.

resource "aws_iam_policy" "ansible_ssm_transfer" {
  name = "logbeacon-ansible-ssm-s3-transfer"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AnsibleSsmS3Transfer"
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = [
          "arn:aws:s3:::logbeacon-ansible-ssm-transfer",
          "arn:aws:s3:::logbeacon-ansible-ssm-transfer/*"
        ]
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-ansible-ssm-s3-transfer"
    }
  )
}
