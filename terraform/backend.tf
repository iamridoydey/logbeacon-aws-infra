terraform {
  backend "s3" {
    bucket = "logbeacon-state-file"
    key    = "logbeacon.terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}