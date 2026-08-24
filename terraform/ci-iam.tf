# =============================================================
# GITHUB OIDC PROVIDER
# =============================================================
module "iam_oidc_provider" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"

  url = "https://token.actions.githubusercontent.com"

  tags = {
    Name = "github-oidc-provider"
    Environment = var.environment
  }
}
# =============================================================
# logbeacon-app repo ci role
# =============================================================
module "logbeacon_app_ci_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role"
  name = "logbeacon-app-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = ["repo:iamridoydey/logbeacon-app:ref:refs/heads/main"]

  policies = {
    EcrReadWrite = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  }

  tags = {
    Name = "logbeacon-app-ci-role"
    Environment = var.environment
  }
}



# =============================================================
# logbeacon-infra repo ci role
# =============================================================
module "logbeacon_infra_bootstrap_ci_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role"
  name = "logbeacon-infrabootstrap-ci-role"

  enable_github_oidc = true

  oidc_wildcard_subjects = ["repo:iamridoydey/logbeacon-aws-infra:ref:refs/heads/main"]

  policies = {
    EksClusterPolicy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    workloadEksCredReadWritePolicy = aws_iam_policy.workload_cred_read_write.arn
  }

  tags = {
    Name = "logbeacon-infra-bootstrap-ci-role"
    Environment = var.environment
  }
}
