# ------------------------------------------
#                 Project
#-------------------------------------------
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "logbeacon"
}


variable "environment" {
  description = "Environment"
  type        = string
}



# ------------------------------------------
#                   AWS
#-------------------------------------------
variable "default_region" {
  description = "Default region"
  type        = string
  default     = "us-east-1"
}



# ------------------------------------------
#                   VPC
#-------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "public_subnets" {
  description = "Public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}


variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}




# ------------------------------------------
#                 SECRET
#-------------------------------------------
variable "logbeacon_secrets" {
  description = "LogBeacon app secret values"
  type = object({
    # Backend
    sqlalchemy_track_modifications = string
    secret_key                     = string
    groq_api_key                   = string

    # Email
    smtp_user                      = string
    smtp_password                  = string
    from_email                     = string

    # Frontend
    session_secret = string

    # Postgres
    postgres_user     = string
    postgres_password = string
    postgres_db       = string
  })
  sensitive = true
}


variable "cloudflare_secrets" {
  type = object({
    account_id = string
    api_token  = string
    zone_id    = string
  })
  sensitive = true
}


variable "github_secrets" {
  type = object({
    username = string
    token = string
  })
  sensitive = true
}


variable "sonarqube_admin_password" {
  description = "Sonarqube admin password"
  type = string
  sensitive = true
}
