# =============================================================
#              ARGO CD MANAGEMENT IAM ROLE
# =============================================================
#
# This is the initial AWS identity used by Argo CD pods
# running inside the MANAGEMENT EKS cluster.
#
# Pod Identity:
#
#   Argo CD ServiceAccount
#          |
#          v
#   argocd-management-role
#
# This role is then allowed to assume the workload-cluster role.
# =============================================================

resource "aws_iam_role" "argocd_management_role" {
  name = "argocd-management-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowEksPodIdentity"
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]

        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes-namespace" = "argocd"

            "aws:RequestTag/kubernetes-service-account" = [
              "argocd-application-controller",
              "argocd-server"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "argocd-management-role"
    }
  )
}


# =============================================================
#              ARGO CD WORKLOAD EKS IAM ROLE
# =============================================================
#
# This is the IAM identity Argo CD uses when authenticating
# to the WORKLOAD EKS cluster.
#
# It is NOT attached directly through Pod Identity.
#
# argocd-management-role assumes this role.
#
# Kubernetes authorization is granted through the workload
# EKS Access Entry.
# =============================================================

resource "aws_iam_role" "argocd_workload_eks_role" {
  name = "argocd-workload-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowArgoCdManagementRole"
        Effect = "Allow"

        Principal = {
          AWS = aws_iam_role.argocd_management_role.arn
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "argocd-workload-eks-role"
    }
  )
}


# =============================================================
#       ALLOW MANAGEMENT ROLE TO ASSUME WORKLOAD ROLE
# =============================================================
#
# This policy gives argocd-management-role permission to call
# STS AssumeRole against argocd-workload-eks-role.
# =============================================================

resource "aws_iam_policy" "argocd_assume_workload_policy" {
  name = "argocd-assume-workload-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AssumeWorkloadEksRole"
        Effect = "Allow"

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]

        Resource = aws_iam_role.argocd_workload_eks_role.arn
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "argocd-assume-workload-policy"
    }
  )
}


# =============================================================
#       ATTACH ASSUME-ROLE POLICY TO MANAGEMENT ROLE
# =============================================================

resource "aws_iam_role_policy_attachment" "argocd_assume_workload_attachment" {
  role       = aws_iam_role.argocd_management_role.name
  policy_arn = aws_iam_policy.argocd_assume_workload_policy.arn
}


# =============================================================
#       MANAGEMENT EKS -> ARGO CD POD IDENTITIES
# =============================================================

locals {
  argocd_management_pod_identity_associations = {
    application_controller = "argocd-application-controller"
    applicationset_controller = "argocd-applicationset-controller"
    server = "argocd-server"
  }
}

resource "aws_eks_pod_identity_association" "argocd_management" {
  for_each = local.argocd_management_pod_identity_associations

  cluster_name    = module.management_eks.cluster_name
  namespace       = "argocd"
  service_account = each.value
  role_arn        = aws_iam_role.argocd_management_role.arn

  tags = merge(
    local.common_tags,
    {
      Name = "argocd-management-pod-identity-${each.key}"
    }
  )
}