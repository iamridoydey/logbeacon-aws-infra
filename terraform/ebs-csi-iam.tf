resource "aws_iam_role" "ebs_csi_role" {
  name = "ebs-csi-role-${var.environment}"

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
    Name        = "ebs-csi-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
}

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "ebs-csi-pod-identity"

  associations = {
    ebs_csi = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      role_arn        = aws_iam_role.ebs_csi_role.arn
    }
  }

  tags = {
    Environment = var.environment
    Name        = "ebs-csi-pod-identity"
  }
}