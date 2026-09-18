# =============================================================
# All Secrets KMS
# =============================================================
resource "aws_kms_key" "logbeacon_kms_key" {
  description             = "An example symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "logbeacon-kms-key"
    Statement = [
      {
        Sid    = "Enable root account permission"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# =============================================================
# Management Cluster KMS
# =============================================================
resource "aws_kms_key" "management_cluster" {
  description             = "KMS key for management EKS cluster secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSClusterUseOfKey"
        Effect = "Allow"
        Principal = {
          AWS = module.management_eks.cluster_iam_role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_kms_alias" "management_cluster" {
  name          = "alias/eks/logbeacon-management-cluster"
  target_key_id = aws_kms_key.management_cluster.key_id
}

# =============================================================
# Workload Cluster KMS
# =============================================================
resource "aws_kms_key" "workload_cluster" {
  description             = "KMS key for workload EKS cluster secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSClusterUseOfKey"
        Effect = "Allow"
        Principal = {
          AWS = module.workload_eks.cluster_iam_role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_kms_alias" "workload_cluster" {
  name          = "alias/eks/logbeacon-workload-cluster"
  target_key_id = aws_kms_key.workload_cluster.key_id
}
