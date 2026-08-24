data "aws_caller_identity" "current" {}

# =============================================================
# LogBeacon Application Secret
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_app" {
  name        = "logbeacon/app"
  description = "LogBeacon application credentials."

  tags = {
    Name        = "logbeacon-app"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "logbeacon_app" {
  secret_id = aws_secretsmanager_secret.logbeacon_app.id

  secret_string = jsonencode({
    # Backend
    SECRET_KEY                     = var.logbeacon_secrets.secret_key
    GROQ_API_KEY                   = var.logbeacon_secrets.groq_api_key
    # Frontend
    SESSION_SECRET = var.logbeacon_secrets.session_secret
  })
}


# =============================================================
# LogBeacon PostgreSQL Secret
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_database" {
  name        = "logbeacon/database"
  description = "LogBeacon PostgreSQL credentials."

  tags = {
    Name        = "logbeacon-database"
    Environment = var.environment
  }
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
# LogBeacon SMTP Secret
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_smtp" {
  name        = "logbeacon/smtp"
  description = "LogBeacon SMTP credentials."

  tags = {
    Name        = "logbeacon-smtp"
    Environment = var.environment
  }
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
# LogBeacon Cloudflare Secret
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_cloudflare" {
  name        = "logbeacon/cloudflare"
  description = "LogBeacon Cloudflare credentials."

  tags = {
    Name        = "logbeacon-cloudflare"
    Environment = var.environment
  }
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
# LogBeacon workload eks credential
# =============================================================

resource "aws_secretsmanager_secret" "workload_eks_cred" {
  name        = "workload-eks-cred"
  description = "LogBeacon workload eks credentials."

  tags = {
    Name        = "logbeacon-cloudflare"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "workload_eks_cred" {
  secret_id = aws_secretsmanager_secret.workload_eks_cred.id

  secret_string = jsonencode({
    SERVER = module.workload_eks.cluster_endpoint
    CA_DATA = module.workload_eks.cluster_certificate_authority_data
  })
}