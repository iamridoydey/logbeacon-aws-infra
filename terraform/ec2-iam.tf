
resource "aws_iam_role" "logbeacon_admin_role" {
  name = "logbeacon-admin-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name        = "logbeacon-admin-role"
    Environment = var.environment
  }
}


# =========================================================================
#   Allow logbeacon admin to access management and workload cluster
# =========================================================================

resource "aws_iam_policy" "management_eks_access_policy" {
  name = "management-eks-access-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = module.management_eks.cluster_arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "management_eks_attachment" {
  role       = aws_iam_role.logbeacon_admin_role.name
  policy_arn = aws_iam_policy.management_eks_access_policy.arn
}



resource "aws_iam_policy" "workload_eks_access_policy" {
  name = "workload-eks-access-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = module.workload_eks.cluster_arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "workload_eks_attachment" {
  role       = aws_iam_role.logbeacon_admin_role.name
  policy_arn = aws_iam_policy.workload_eks_access_policy.arn
}


# Session management policy attachment
resource "aws_iam_role_policy_attachment" "logbeacon_admin_ssm" {
  role       = aws_iam_role.logbeacon_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ==========================================================
#         Iam instance profile
# ==========================================================
resource "aws_iam_instance_profile" "logbeacon_admin" {
  name = "logbeacon-admin-${var.environment}"

  role = aws_iam_role.logbeacon_admin_role.name
}