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

  recovery_window_in_days = 0
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_secretsmanager_secret_version" "logbeacon_app" {
  secret_id = aws_secretsmanager_secret.logbeacon_app.id

  secret_string = jsonencode({
    # Backend
    SECRET_KEY   = var.logbeacon_secrets.secret_key
    GROQ_API_KEY = var.logbeacon_secrets.groq_api_key
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

  recovery_window_in_days = 0

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
# LogBeacon SMTP Secret
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_smtp" {
  name        = "logbeacon/smtp"
  description = "LogBeacon SMTP credentials."

  tags = {
    Name        = "logbeacon-smtp"
    Environment = var.environment
  }

  recovery_window_in_days = 0

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
# LogBeacon Cloudflare Secret
# =============================================================

resource "aws_secretsmanager_secret" "logbeacon_cloudflare" {
  name        = "logbeacon/cloudflare"
  description = "LogBeacon Cloudflare credentials."

  tags = {
    Name        = "logbeacon-cloudflare"
    Environment = var.environment
  }

  recovery_window_in_days = 0

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
# LogBeacon github Secret
# =============================================================

resource "aws_secretsmanager_secret" "github_secret" {
  name        = "github-secret"
  description = "Github secret"

  tags = {
    Name        = "github-secret"
    Environment = var.environment
  }

  recovery_window_in_days = 0

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_secretsmanager_secret_version" "github_secret" {
  secret_id = aws_secretsmanager_secret.github_secret.id

  secret_string = jsonencode({
    USERNAME = var.github_secrets.username
    TOKEN  = var.github_secrets.token
  })
}



# =============================================================
# LogBeacon workload eks credential
# =============================================================

resource "aws_secretsmanager_secret" "workload_eks_cred" {
  name        = "workload-eks-cred"
  description = "LogBeacon workload eks credentials."

  tags = {
    Name        = "workload-eks-cred"
    Environment = var.environment
  }


  recovery_window_in_days = 0

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_secretsmanager_secret_version" "workload_eks_cred" {
  secret_id = aws_secretsmanager_secret.workload_eks_cred.id

  secret_string = jsonencode({
    SERVER  = module.workload_eks.cluster_endpoint
    CA_DATA = module.workload_eks.cluster_certificate_authority_data
  })

}



# =============================================================
# LogBeacon sonarqube admin cred
# =============================================================
resource "aws_secretsmanager_secret" "sonarqube_admin_password" {
  name        = "sonarqube-admin-password"
  description = "SonarQube admin password "

  tags = {
    Name        = "sonarqube-admin-password"
    Environment = var.environment
  }

  recovery_window_in_days = 0

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
# LogBeacon sonarqube ci credential
# =============================================================

resource "aws_secretsmanager_secret" "sonarqube_ci_cred" {
  name        = "sonarqube-ci-cred"
  description = "Sonarqube ci credentials."

  tags = {
    Name        = "sonarqube-ci-cred"
    Environment = var.environment
  }

  recovery_window_in_days = 0

  # lifecycle {
  #   prevent_destroy = true
  # }
}

