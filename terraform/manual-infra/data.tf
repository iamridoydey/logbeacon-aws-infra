# =============================================================
#                    AWS ACCOUNT ID
# =============================================================

data "aws_caller_identity" "current" {}


# ============================================================================
# Fetch the TLS certificate from the OIDC issuer URL to get the thumbprint
# ============================================================================
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}
