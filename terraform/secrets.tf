# =============================================================
# LOGBEACON APPLICATION SECRET
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_app" {
  name        = "logbeacon/app"
  description = "LogBeacon application credentials."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-app"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "logbeacon_app" {
  secret_id = aws_secretsmanager_secret.logbeacon_app.id

  secret_string = jsonencode({
    SECRET_KEY     = var.logbeacon_secrets.secret_key
    GROQ_API_KEY   = var.logbeacon_secrets.groq_api_key
    SESSION_SECRET = var.logbeacon_secrets.session_secret
  })
}


# =============================================================
# LOGBEACON POSTGRESQL SECRET
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_database" {
  name        = "logbeacon/database"
  description = "LogBeacon PostgreSQL credentials."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-database"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "logbeacon_database" {
  secret_id = aws_secretsmanager_secret.logbeacon_database.id

  secret_string = jsonencode({
    POSTGRES_USER     = var.logbeacon_secrets.postgres_user
    POSTGRES_PASSWORD = var.logbeacon_secrets.postgres_password
    POSTGRES_DB       = var.logbeacon_secrets.postgres_db
  })
}


# =============================================================
# LOGBEACON SMTP SECRET
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_smtp" {
  name        = "logbeacon/smtp"
  description = "LogBeacon SMTP credentials."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-smtp"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "logbeacon_smtp" {
  secret_id = aws_secretsmanager_secret.logbeacon_smtp.id

  secret_string = jsonencode({
    SMTP_USER     = var.logbeacon_secrets.smtp_user
    SMTP_PASSWORD = var.logbeacon_secrets.smtp_password
    FROM_EMAIL    = var.logbeacon_secrets.from_email
  })
}


# =============================================================
# LOGBEACON CLOUDFLARE SECRET
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_cloudflare" {
  name        = "logbeacon/cloudflare"
  description = "LogBeacon Cloudflare credentials."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-cloudflare"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "logbeacon_cloudflare" {
  secret_id = aws_secretsmanager_secret.logbeacon_cloudflare.id

  secret_string = jsonencode({
    ACCOUNT_ID = var.cloudflare_secrets.account_id
    API_TOKEN  = var.cloudflare_secrets.api_token
    ZONE_ID    = var.cloudflare_secrets.zone_id
  })
}


# =============================================================
# GITHUB SECRET
# =============================================================

resource "aws_secretsmanager_secret" "github_secret" {
  name        = "github-secret"
  description = "GitHub credentials used by Argo CD components."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "github-secret"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "github_secret" {
  secret_id = aws_secretsmanager_secret.github_secret.id

  secret_string = jsonencode({
    USERNAME = var.github_secrets.username
    TOKEN    = var.github_secrets.token
  })
}


# =============================================================
# WORKLOAD EKS CONNECTION CREDENTIALS
# =============================================================
#
# These values are consumed by the management cluster's
# External Secrets controller to construct the Argo CD
# cluster Secret used to connect to workload EKS.
# =============================================================

resource "aws_secretsmanager_secret" "workload_eks_cred" {
  name        = "workload-eks-cred"
  description = "Workload EKS connection information for Argo CD."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "workload-eks-cred"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "workload_eks_cred" {
  secret_id = aws_secretsmanager_secret.workload_eks_cred.id

  secret_string = jsonencode({
    WORKLOAD_CLUSTER_NAME     = module.workload_eks.cluster_name
    WORKLOAD_CLUSTER_ROLE_ARN = aws_iam_role.argocd_workload_eks_role.arn

    SERVER  = module.workload_eks.cluster_endpoint
    CA_DATA = module.workload_eks.cluster_certificate_authority_data
  })
}


# =============================================================
# SONARQUBE ADMIN CREDENTIAL
# =============================================================

resource "aws_secretsmanager_secret" "sonarqube_admin_password" {
  name        = "sonarqube-admin-password"
  description = "SonarQube administrator password."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "sonarqube-admin-password"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_secretsmanager_secret_version" "sonarqube_admin_password" {
  secret_id = aws_secretsmanager_secret.sonarqube_admin_password.id

  secret_string = jsonencode({
    ADMIN_PASSWORD = var.sonarqube_admin_password
  })
}


# =============================================================
# SONARQUBE CI CREDENTIAL
# =============================================================
#
# Terraform creates the Secrets Manager secret itself.
#
# The SonarQube bootstrap Job later generates the SonarQube
# CI token and stores its value using PutSecretValue.
#
# Therefore Terraform does NOT manage a secret version here.
# =============================================================

resource "aws_secretsmanager_secret" "sonarqube_ci_cred" {
  name        = "sonarqube-ci-cred"
  description = "SonarQube CI credentials."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = "sonarqube-ci-cred"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}