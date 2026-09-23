logbeacon_secrets = {
  sqlalchemy_track_modifications = "false"
  secret_key                     = "secret key"
  groq_api_key                   = "grok api key"
  smtp_user                      = "smtp user"
  smtp_password                  = "smtp password"
  from_email                     = "email"

  session_secret = "session secret "

  postgres_user     = "postgres user"
  postgres_password = "postgres password"
  postgres_db       = "postgres db name"
}


github_secrets = {
  username = "github id"
  token    = "github token"
}

cloudflare_secrets = {
  account_id = "cloudflare id "
  api_token  = "api token"
  zone_id    = "zone id"
}


sonarqube_admin_password = "admin pass"
environment              = "env"

sonarqube_monitoring_passcode = "sonarqube monitoring passcode"
