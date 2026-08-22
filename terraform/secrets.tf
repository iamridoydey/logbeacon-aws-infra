resource "aws_secretsmanager_secret" "logbeacon_app_secret" {
  name        = "logbeacon-app-secret"
  description = "Logbeacon app credentials."
}

resource "aws_secretsmanager_secret_version" "logbeacon_app_secret_val" {
  secret_id = aws_secretsmanager_secret.logbeacon_app_secret.id

  secret_string = jsonencode({
    # Backend env
    SQLALCHEMY_TRACK_MODIFICATIONS = var.logbeacon_secrets.sqlalchemy_track_modifications
    SECRET_KEY                     = var.logbeacon_secrets.secret_key
    GROQ_API_KEY                   = var.logbeacon_secrets.groq_api_key
    GROQ_MODEL                     = var.logbeacon_secrets.groq_model
    CHAT_RETENTION_DAYS            = var.logbeacon_secrets.chat_retention_days
    MAX_ERROR_LENGTH               = var.logbeacon_secrets.max_error_length
    PRICE_PER_MILLION_TOKENS       = var.logbeacon_secrets.price_per_million_tokens
    SMTP_HOST                      = var.logbeacon_secrets.smtp_host
    SMTP_PORT                      = var.logbeacon_secrets.smtp_port
    SMTP_USER                      = var.logbeacon_secrets.smtp_user
    SMTP_PASSWORD                  = var.logbeacon_secrets.smtp_password
    FROM_EMAIL                     = var.logbeacon_secrets.from_email

    # Frontend env
    SESSION_SECRET = var.logbeacon_secrets.session_secret

    # Postgresql env
    POSTGRES_USER     = var.logbeacon_secrets.postgres_user
    POSTGRES_PASSWORD = var.logbeacon_secrets.postgres_password
    POSTGRES_DB       = var.logbeacon_secrets.postgres_db
  })
}