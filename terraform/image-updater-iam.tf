# =============================================================
#              ARGO IMAGE UPDATER IAM ROLE
# =============================================================
#
# Argo Image Updater runs inside the MANAGEMENT EKS cluster.
#
# Its job is to:
#   1. Check ECR for new image versions/digests.
#   2. Detect a new version.
#   3. Update the image reference used by Argo CD.
#   4. Optionally write the change back to Git.
#
# This IAM role is only for AWS/ECR access.
# GitHub/Git credentials are handled separately.
# =============================================================

resource "aws_iam_role" "argo_image_updater_role" {

  name = "argo-image-updater-role-${var.environment}"

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
    Name        = "argo-image-updater-role"
    Environment = var.environment
  }
}


# =============================================================
#              ECR READ-ONLY PERMISSION
# =============================================================
#
# Image Updater only needs to inspect ECR.
#
# It needs to discover:
#   - available image tags
#   - image digests
#   - image metadata
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
#              EKS POD IDENTITY
# =============================================================
#
# This connects the Kubernetes ServiceAccount used by
# Argo Image Updater to the IAM role above.
#
# Image Updater runs in the MANAGEMENT cluster because
# Argo CD runs in the management cluster.
# =============================================================

module "argo_image_updater_pod_identity" {

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "argo-image-updater-pod-identity"

  associations = {

    image_updater = {

      cluster_name = module.management_eks.cluster_name

      namespace = "argocd"

      service_account = "argocd-image-updater"

      role_arn = aws_iam_role.argo_image_updater_role.arn
    }
  }

  tags = {

    Environment = var.environment

    Name = "argo-image-updater-pod-identity"
  }
}