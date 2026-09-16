# ------------------------------------------
#                 Project
#-------------------------------------------
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "logbeacon"
}

variable "default_region" {
  description = "Default region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment"
  type        = string
}


variable "github_username" {
  description = "Github username"
  type        = string
}
