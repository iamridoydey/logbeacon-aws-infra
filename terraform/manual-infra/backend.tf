terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.29"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
  }
  backend "s3" {
    bucket       = "logbeacon-state-file"
    key          = "manual-infra.terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
