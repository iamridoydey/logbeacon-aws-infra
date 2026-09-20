locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }



  state_bucket = "logbeacon-state-file"
  state_key    = "logbeacon.terraform.tfstate"
  lock_key     = "logbeacon.terraform.tfstate.tflock"

  app_buckets = [
    "arn:aws:s3:::logbeacon-ansible-ssm-transfer",
    "arn:aws:s3:::logbeacon-log-bucket",
  ]

  secret_arns = [
    "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:github-secret*",
    "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:github_secret*",
    "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:logbeacon*",
    "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:sonarqube*",
    "arn:aws:secretsmanager:${var.default_region}:${data.aws_caller_identity.current.account_id}:secret:workload-eks-cred*",
  ]
}
