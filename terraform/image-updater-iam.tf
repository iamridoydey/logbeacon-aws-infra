# =============================================================
#              ARGO IMAGE UPDATER IAM ROLE
# =============================================================
#
# Argo CD Image Updater runs inside the MANAGEMENT EKS cluster.
#
# Its AWS responsibility is only to:
#   1. Authenticate to Amazon ECR.
#   2. Inspect available image tags/digests.
#   3. Detect new image versions.
#
# Git write-back authentication is handled separately through
# the GitHub credentials available to Argo CD Image Updater.
# =============================================================

resource "aws_iam_role" "argo_image_updater_role" {
  name = "argo-image-updater-role"

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

  tags = merge(
    local.common_tags,
    {
      Name = "argo-image-updater-role"
    }
  )
}


# =============================================================
#              ECR READ-ONLY PERMISSION
# =============================================================
#
# Image Updater only needs to inspect ECR repositories.
#
# It does NOT need permission to:
#   - push images
#   - delete images
#   - modify repositories
# =============================================================

resource "aws_iam_role_policy_attachment" "argo_image_updater_ecr" {
  role       = aws_iam_role.argo_image_updater_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# =============================================================
#              ARGO IMAGE UPDATER POD IDENTITY
# =============================================================
#
# Maps:
#
# Management EKS
#   argocd namespace
#       argocd-image-updater ServiceAccount
#                   |
#                   v
#       argo-image-updater-role
#
# The Pod Identity Agent supplies temporary AWS credentials
# for this IAM role to the Image Updater pod.
# =============================================================

module "argo_image_updater_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "argo-image-updater-pod-identity"

  associations = {
    image_updater = {
      cluster_name    = module.management_eks.cluster_name
      namespace       = "argocd"
      service_account = "argocd-image-updater"
      role_arn        = aws_iam_role.argo_image_updater_role.arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "argo-image-updater-pod-identity"
    }
  )
}
