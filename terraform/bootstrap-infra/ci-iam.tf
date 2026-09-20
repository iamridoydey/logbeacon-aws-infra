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
    "repo:${var.github_username}/logbeacon-app:ref:refs/heads/main",
    "repo:${var.github_username}/logbeacon-app:pull_request",
    "repo:${var.github_username}/logbeacon-app:environment:app-release-production",
  ]

  policies = {
    EcrReadWrite      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    SonarqubeCredRead = aws_iam_policy.sonarqube_cred_read_policy.arn
  }

  tags = merge(local.common_tags, { Name = "logbeacon-app-ci-role" })
}

# =============================================================
# INFRA PR ROLE
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
    InfraRead     = aws_iam_policy.main_infra_read.arn
  }

  tags = merge(local.common_tags, { Name = "logbeacon-infra-bootstrap-pr-role" })
}

# =============================================================
# INFRA MERGE ROLE
# =============================================================

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
    MainInfraApply = aws_iam_policy.main_infra_apply.arn
    InfraRead      = aws_iam_policy.main_infra_read.arn
    SsmAdmin       = aws_iam_policy.infra_ci_ssm_access.arn
  }

  tags = merge(local.common_tags, { Name = "logbeacon-infra-bootstrap-ci-role" })
}


# =============================================================
# STATE + LOCK (PR and shared reads)
# =============================================================

resource "aws_iam_policy" "terraform_state_access" {
  name        = "logbeacon-terraform-state-access"
  description = "S3 state and lock for PR plans"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStateBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:GetBucketVersioning"]
        Resource = "arn:aws:s3:::${local.state_bucket}"
      },
      {
        Sid    = "ReadWriteStateAndLock"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${local.state_bucket}/${local.state_key}",
          "arn:aws:s3:::${local.state_bucket}/${local.lock_key}"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "logbeacon-terraform-state-access" })
}

# =============================================================
# READ / DESCRIBE
# =============================================================

resource "aws_iam_policy" "main_infra_read" {
  #checkov:skip=CKV_AWS_355:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
  name        = "logbeacon-main-infra-read"
  description = "Describe/list existing main-infra so terraform plan can refresh"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Ec2Describe"
        Effect   = "Allow"
        Action   = ["ec2:Describe*", "ec2:GetSecurityGroupsForVpc"]
        Resource = "*"
      },
      {
        Sid    = "EksDescribe"
        Effect = "Allow"
        Action = [
          "eks:Describe*",
          "eks:List*",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      {
        Sid    = "IamRead"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetInstanceProfile",
          "iam:GetOpenIDConnectProvider",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListPolicyVersions",
          "iam:ListInstanceProfiles",
          "iam:ListOpenIDConnectProviders",
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListPolicyTags",
          "iam:ListRoleTags",
          "iam:ListInstanceProfileTags",
          "iam:ListOpenIDConnectProviderTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "KmsRead"
        Effect = "Allow"
        Action = [
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:ListResourceTags"
        ]
        Resource = "*"
      },
      {
        # Reading a secret value encrypted with a customer-managed key also
        # needs kms:Decrypt. Limited to use through Secrets Manager only.
        Sid      = "KmsDecryptForSecrets"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "arn:aws:kms:${var.default_region}:${data.aws_caller_identity.current.account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.default_region}.amazonaws.com"
          }
        }
      },
      {
        Sid      = "SecretsDescribe"
        Effect   = "Allow"
        Action   = ["secretsmanager:DescribeSecret", "secretsmanager:GetResourcePolicy", "secretsmanager:ListSecrets"]
        Resource = "*"
      },
      {
        Sid      = "SecretsGetForPlanRefresh"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = local.secret_arns
      },
      {
        Sid    = "S3ReadAppBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketLogging",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetAccelerateConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::logbeacon-log-bucket",
          "arn:aws:s3:::logbeacon-ansible-ssm-transfer"
        ]
      },
      {
        Sid    = "EcrRead"
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories",
          "ecr:GetLifecyclePolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:ListTagsForResource"
        ]
        Resource = "arn:aws:ecr:${var.default_region}:${data.aws_caller_identity.current.account_id}:repository/logbeacon/*"
      },
      {
        Sid      = "SsmEksAmi"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.default_region}::parameter/aws/service/eks/optimized-ami/*"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "logbeacon-main-infra-read" })
}
# =============================================================
# APPLY / DESTROY
# =============================================================

resource "aws_iam_policy" "main_infra_apply" {
  #checkov:skip=CKV_AWS_286:Protected apply role creates LogBeacon IAM roles and passes them to EKS/EC2
  #checkov:skip=CKV_AWS_287:Manages approved secrets and KMS keys
  #checkov:skip=CKV_AWS_288:Create APIs often require Resource *
  #checkov:skip=CKV_AWS_289:Manages resource policies for provisioned infra
  #checkov:skip=CKV_AWS_290:Protected production apply role
  #checkov:skip=CKV_AWS_355:Some create/list APIs do not support resource-level permissions

  name        = "logbeacon-main-infra-apply"
  description = "Write path for terraform apply/destroy of main-infra"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StateWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.state_bucket}",
          "arn:aws:s3:::${local.state_bucket}/*"
        ]
      },
      {
        Sid    = "AppBuckets"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:Get*",
          "s3:PutBucket*",
          "s3:PutEncryptionConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutBucketLogging",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = concat(local.app_buckets, [for b in local.app_buckets : "${b}/*"])
      },
      {
        Sid      = "DestroyVersionedBuckets"
        Effect   = "Allow"
        Action   = ["s3:DeleteObjectVersion", "s3:ListBucketVersions"]
        Resource = concat(local.app_buckets, [for b in local.app_buckets : "${b}/*"])
      },
      {
        Sid      = "ServiceLinkedRoles"
        Effect   = "Allow"
        Action   = ["iam:CreateServiceLinkedRole"]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*"
      },
      {
        Sid      = "Ec2Write"
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.default_region
          }
        }
      },
      {
        Sid      = "EksWrite"
        Effect   = "Allow"
        Action   = ["eks:*"]
        Resource = "*"
      },
      {
        Sid    = "IamWriteLogbeacon"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRoleToEksEc2Pods"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "eks.amazonaws.com",
              "ec2.amazonaws.com",
              "pods.eks.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid      = "KmsCreateKey"
        Effect   = "Allow"
        Action   = ["kms:CreateKey"]
        Resource = "*"
      },
      {
        Sid    = "KmsWrite"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:UpdateAlias",
          "kms:EnableKeyRotation",
          "kms:PutKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:CreateGrant",
          "kms:RevokeGrant",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          "arn:aws:kms:${var.default_region}:${data.aws_caller_identity.current.account_id}:key/*",
          "arn:aws:kms:${var.default_region}:${data.aws_caller_identity.current.account_id}:alias/*"
        ]
      },
      {
        Sid    = "SecretsWrite"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:RestoreSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:DeleteResourcePolicy"
        ]
        Resource = local.secret_arns
      },
      {
        Sid    = "EcrWrite"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:PutLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
        Resource = "arn:aws:ecr:${var.default_region}:${data.aws_caller_identity.current.account_id}:repository/logbeacon/*"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "logbeacon-main-infra-apply" })
}

# =============================================================
# SSM — runner -> admin instance
# =============================================================

resource "aws_iam_policy" "infra_ci_ssm_access" {
  name        = "infra-ci-ssm-access"
  description = "GitHub apply job sends bootstrap commands to the admin EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SsmRead"
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      },
      {
        Sid    = "SsmDocuments"
        Effect = "Allow"
        Action = ["ssm:SendCommand", "ssm:StartSession"]
        Resource = [
          "arn:aws:ssm:${var.default_region}::document/AWS-RunShellScript",
          "arn:aws:ssm:${var.default_region}:${data.aws_caller_identity.current.account_id}:document/SSM-SessionManagerRunShell"
        ]
      },
      {
        Sid      = "SsmOwnSessions"
        Effect   = "Allow"
        Action   = ["ssm:TerminateSession", "ssm:ResumeSession"]
        Resource = "arn:aws:ssm:*:*:session/$${aws:userid}-*"
      },
      {
        Sid      = "SsmTargetAdmin"
        Effect   = "Allow"
        Action   = ["ssm:SendCommand", "ssm:StartSession"]
        Resource = "arn:aws:ec2:${var.default_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          StringEquals = {
            "ssm:resourceTag/Role" = "logbeacon-admin"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "infra-ci-ssm-access" })
}

# =============================================================
# APP CI — Sonar secret
# =============================================================

resource "aws_iam_policy" "sonarqube_cred_read_policy" {
  name = "sonarqube-cred-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSonarqubeCiCredentials"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:sonarqube-ci-cred*"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "sonarqube-cred-read-policy" })
}
