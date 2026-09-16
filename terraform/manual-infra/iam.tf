# =============================================================
# GITHUB OIDC PROVIDER — created ONCE, here, applied manually.
# Do not duplicate this in bootstrap-infra or main-infra.
# =============================================================
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}


# =============================================================
# BOOTSTRAP PIPELINE ROLE
# Narrow, single-purpose: only allowed to manage the CI-facing
# IAM roles/policies that bootstrap-infra creates. Nothing else.
# =============================================================
resource "aws_iam_role" "bootstrap_infra_role" {
  name = "bootstrap-infra-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "BootstrapInfraRole"
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"

        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              # Repo that created before 19 aug need to attach account id with username and repo id with repo name
              "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:pull_request",
              "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:ref:refs/heads/main",
              "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:environment:bootstrap-production"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "bootstrap-infra-role"
    }
  )
}


# =============================================================
# BOOTSTRAP PIPELINE POLICY
# =============================================================
resource "aws_iam_role_policy" "bootstrap_infra_policy" {
  name = "bootstrap-infra-policy"
  role = aws_iam_role.bootstrap_infra_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowManageCiIamRolesAndPolicies"
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicyVersions",
          "iam:ListInstanceProfilesForRole",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:PassRole"
        ]

        Resource = "*"
      },

      {
        Sid    = "AllowListTerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = var.s3_state_bucket_arn
      },

      {
        Sid    = "AllowTerraformStateAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = [
          "${var.s3_state_bucket_arn}/bootstrap-infra.terraform.tfstate"
        ]
      },

      {
        Sid    = "AllowTerraformStateLockAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "${var.s3_state_bucket_arn}/bootstrap-infra.terraform.tfstate.tflock"
        ]
      }
    ]
  })
}
