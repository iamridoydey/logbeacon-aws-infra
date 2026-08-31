data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "logbeacon_admin" {
  region = var.default_region
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id = module.vpc.private_subnets[0]
  associate_public_ip_address = false

  security_groups = [aws_security_group.logbeacon_admin.id]

  iam_instance_profile = aws_iam_instance_profile.logbeacon_admin.name


  tags = {
    Name = "${var.project_name}-admin"
  }
}

