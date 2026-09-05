# =============================================================
# ECR LIFECYCLE POLICY
# =============================================================

locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 50 tagged images"

        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = 50
        }

        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 14 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countNumber = 14
          countUnit   = "days"
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}


# =============================================================
# FRONTEND ECR REPOSITORY
# =============================================================

module "ecr_frontend" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${var.project_name}/frontend"
  repository_type = "private"

  repository_image_tag_mutability = "IMMUTABLE"
  repository_image_scan_on_push   = true

  repository_lifecycle_policy = local.ecr_lifecycle_policy

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-frontend"
    }
  )
}


# =============================================================
# BACKEND ECR REPOSITORY
# =============================================================

module "ecr_backend" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${var.project_name}/backend"
  repository_type = "private"

  repository_image_tag_mutability = "IMMUTABLE"
  repository_image_scan_on_push   = true

  repository_lifecycle_policy = local.ecr_lifecycle_policy

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-backend"
    }
  )
}