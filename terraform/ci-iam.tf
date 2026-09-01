# =============================================================
# GITHUB OIDC PROVIDER
# =============================================================
module "iam_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"

  url = "https://token.actions.githubusercontent.com"

  tags = {
    Name        = "github-oidc-provider"
    Environment = var.environment
  }
}
# =============================================================
# logbeacon-app repo ci role
# =============================================================
module "logbeacon_app_ci_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"
  name   = "logbeacon-app-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = ["repo:iamridoydey/logbeacon-app:ref:refs/heads/main"]

  policies = {
    EcrReadWrite           = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    SonarqubeCredRead = aws_iam_policy.sonarqube_cred_read.arn
  }

  tags = {
    Name        = "logbeacon-app-ci-role"
    Environment = var.environment
  }
}



# =============================================================
# logbeacon-infra repo ci role
# =============================================================
module "logbeacon_infra_bootstrap_ci_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"
  name   = "logbeacon-infrabootstrap-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = ["repo:iamridoydey/logbeacon-aws-infra:ref:refs/heads/main"]

  policies = {
    EksClusterPolicy               = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    WorkloadEksCredReadWritePolicy = aws_iam_policy.workload_cred_read_write.arn,
    SsmAdminHostAccess             = aws_iam_policy.infra_ci_ssm_access.arn,
    SssmAdminS3Access              = aws_iam_policy.ansible_ssm_transfer.arn
  }

  tags = {
    Name        = "logbeacon-infra-bootstrap-ci-role"
    Environment = var.environment
  }
}

# =============================================================
# logbeacon-app repo ci role
# =============================================================
resource "aws_iam_policy" "infra_ci_ssm_access" {
  name = "infra-ci-ssm-access-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
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
}



# =============================================================
#     Ansible s3 role
# =============================================================
resource "aws_iam_policy" "ansible_ssm_transfer" {
  name = "logbeacon-ansible-ssm-s3-transfer"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
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
    }]
  })
}
