module "ecr_frontend" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${var.project_name}/frontend"

  repository_type = "private"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 50 tagged images"

        selection = {
          tagStatus   = "tagged"
          tagPatternList = ["*"]
          countType   = "imageCountMoreThan"
          countNumber = 50
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

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
  }
}


module "ecr_backend" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${var.project_name}/backend"
  repository_type = "private"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 50 tagged images"

        selection = {
          tagStatus   = "tagged"
          tagPatternList = ["*"]
          countType   = "imageCountMoreThan"
          countNumber = 50
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

  tags = {
    Name        = "${var.project_name}-backend"
    Environment = var.environment
  }
}