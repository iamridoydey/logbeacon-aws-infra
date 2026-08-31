# =============================================================
# LogBeacon EKS Security Groups
# =============================================================

# =============================================================
# Management EKS Security Group
#
# Management EKS:
# - Public endpoint: GitHub Actions / administrator access
# - Private endpoint: VPC-internal access
# =============================================================

module "management_eks_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.project_name}-management-eks"
  description = "Security group for LogBeacon management EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
      description = "HTTPS access to EKS API from inside the VPC"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }

  tags = {
    Name        = "${var.project_name}-management-eks"
    Environment = var.environment
    Cluster     = "management"
  }
}


# =============================================================
# Workload EKS Security Group
#
# Workload EKS:
# - Private endpoint
# - Management cluster / Argo CD accesses it through the VPC
# =============================================================

module "workload_eks_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.project_name}-workload-eks"
  description = "Security group for LogBeacon workload EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
      description = "HTTPS access to EKS API from inside the VPC"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }

  tags = {
    Name        = "${var.project_name}-workload-eks"
    Environment = var.environment
    Cluster     = "workload"
  }
}


# =============================================================
# Logbeacon Admin Security Group for ssm access
# =============================================================
resource "aws_security_group" "logbeacon_admin" {
  name        = "logbeacon-admin-sg-${var.environment}"
  description = "Security group for LogBeacon admin EC2"
  vpc_id      = module.vpc.vpc_id

  # No inbound rules required for SSM
  # ingress = []

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-admin-sg"
    Environment = var.environment
  }
}