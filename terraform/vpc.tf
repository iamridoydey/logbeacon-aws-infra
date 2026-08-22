module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "logbeacon-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnets

  create_igw = true

  tags = {
    Name = var.project_name
    Environment = var.environment
  }
}