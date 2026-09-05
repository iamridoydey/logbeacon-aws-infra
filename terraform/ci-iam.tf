# =============================================================
# GITHUB OIDC PROVIDER
# =============================================================

module "iam_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"

  url = "https://token.actions.githubusercontent.com"

  tags = merge(
    local.common_tags,
    {
      Name = "github-oidc-provider"
    }
  )
}


# =============================================================
# LOGBEACON APP REPO CI ROLE
# =============================================================

module "logbeacon_app_ci_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "logbeacon-app-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:iamridoydey/logbeacon-app:ref:refs/heads/main"
  ]

  policies = {
    EcrReadWrite      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    SonarqubeCredRead = aws_iam_policy.sonarqube_cred_read.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-app-ci-role"
    }
  )
}


# =============================================================
# LOGBEACON INFRA REPO CI ROLE
# =============================================================

module "logbeacon_infra_bootstrap_ci_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "logbeacon-infra-bootstrap-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:iamridoydey/logbeacon-aws-infra:ref:refs/heads/main"
  ]

  policies = {
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
# INFRA CI - SSM ACCESS POLICY
# =============================================================

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
          aws_s3_bucket.ansible_ssm_transfer.arn,
          "${aws_s3_bucket.ansible_ssm_transfer.arn}/*"
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
