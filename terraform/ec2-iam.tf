# =============================================================
#                  LOGBEACON ADMIN IAM ROLE
# =============================================================

resource "aws_iam_role" "logbeacon_admin_role" {
  name = "logbeacon-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-admin-role"
    }
  )
}


# =============================================================
#      ALLOW ADMIN EC2 TO DESCRIBE BOTH EKS CLUSTERS
# =============================================================

resource "aws_iam_policy" "logbeacon_admin_policy" {
  name = "logbeacon-admin-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManagementEksDescribeCluster"
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = module.management_eks.cluster_arn
      },

      {
        Sid    = "WorkloadEksDescribeCluster"
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = module.workload_eks.cluster_arn
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-admin-policy"
    }
  )
}


# =============================================================
#              ATTACH EKS POLICY TO ADMIN ROLE
# =============================================================

resource "aws_iam_role_policy_attachment" "logbeacon_admin_eks" {
  role       = aws_iam_role.logbeacon_admin_role.name
  policy_arn = aws_iam_policy.logbeacon_admin_policy.arn
}


# =============================================================
#              SSM MANAGED INSTANCE ACCESS
# =============================================================

resource "aws_iam_role_policy_attachment" "logbeacon_admin_ssm" {
  role       = aws_iam_role.logbeacon_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# =============================================================
#                    IAM INSTANCE PROFILE
# =============================================================

resource "aws_iam_instance_profile" "logbeacon_admin" {
  name = "logbeacon-admin"

  role = aws_iam_role.logbeacon_admin_role.name

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-admin"
    }
  )
}