# =============================================================
# LOGBEACON APP REPO CI ROLE
# =============================================================

module "logbeacon_app_ci_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.1"

  name            = "logbeacon-app-ci-role"
  use_name_prefix = false

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

  name            = "logbeacon-infra-bootstrap-pr-role"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:pull_request"
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

  name            = "logbeacon-infra-bootstrap-ci-role"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:ref:refs/heads/main",
    "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:environment:main-infra-production",
    "repo:${var.github_username}@${var.github_account_id}/logbeacon-aws-infra@${var.github_repo_id}:environment:main-infra-destroy"
  ]

  policies = {
    TfStateAccess             = aws_iam_policy.terraform_state_access.arn
    WorkloadEksCredReadPolicy = aws_iam_policy.workload_eks_cred_read_policy.arn
    SsmAdminHostAccess        = aws_iam_policy.infra_ci_ssm_access.arn
    SsmAdminS3Access          = aws_iam_policy.ansible_ssm_transfer.arn
    MainInfraApply            = aws_iam_policy.main_infra_apply.arn
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


# =============================================================
# Allow list of permission need for run tf plan on runner
# =============================================================
resource "aws_iam_policy" "main_infra_apply" {
  name = "logbeacon-main-infra-apply"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "VpcEc2Networking"
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
      },
      {
        Sid    = "EksClustersAndIdentity"
        Effect = "Allow"
        Action = [
          "eks:CreateCluster",
          "eks:DescribeCluster",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:DeleteCluster",
          "eks:ListClusters",
          "eks:TagResource",
          "eks:UntagResource",
          "eks:CreateNodegroup",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig",
          "eks:UpdateNodegroupVersion",
          "eks:DeleteNodegroup",
          "eks:ListNodegroups",
          "eks:CreateAddon",
          "eks:DescribeAddon",
          "eks:DescribeAddonVersions",
          "eks:UpdateAddon",
          "eks:DeleteAddon",
          "eks:ListAddons",
          "eks:CreateAccessEntry",
          "eks:DescribeAccessEntry",
          "eks:UpdateAccessEntry",
          "eks:DeleteAccessEntry",
          "eks:ListAccessEntries",
          "eks:AssociateAccessPolicy",
          "eks:DisassociateAccessPolicy",
          "eks:ListAssociatedAccessPolicies",
          "eks:CreatePodIdentityAssociation",
          "eks:DescribePodIdentityAssociation",
          "eks:UpdatePodIdentityAssociation",
          "eks:DeletePodIdentityAssociation",
          "eks:ListPodIdentityAssociations"
        ]
        Resource = "*"
      },
      {
        Sid    = "IamForRolesAndProfiles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:CreatePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:DeletePolicy",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:CreateOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:ListOpenIDConnectProviders",
          "iam:ListRoles",
          "iam:ListPolicies"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRolesThisStackOwns"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "eks.amazonaws.com",
              "ec2.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "KmsForClustersAndSecrets"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:ListResourceTags",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:UpdateAlias",
          "kms:EnableKeyRotation",
          "kms:DisableKeyRotation",
          "kms:PutKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:RestoreSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:DeleteResourcePolicy",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3BucketsThisStackCreates"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "*"
      },
      {
        Sid    = "EcrRepos"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecr:DeleteRepository",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy",
          "ecr:ListTagsForResource",
          "ecr:TagResource",
          "ecr:UntagResource"
        ]
        Resource = "*"
      }
    ]
  })
}
