# =============================================================
#                         VPC
# =============================================================

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "logbeacon-vpc"
  cidr = var.vpc_cidr

  azs = var.azs

  # Public subnets
  public_subnets = var.public_subnets

  # Private subnets
  private_subnets = var.private_subnets

  # Internet Gateway
  create_igw = true

  # NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  # Don't set the public ip on ec2. Since we don't need public ip on ec2
  # map_public_ip_on_launch = true

  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}


