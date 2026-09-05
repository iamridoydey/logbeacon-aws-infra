# =============================================================
# UBUNTU AMI
# =============================================================

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]
  }

  filter {
    name = "virtualization-type"

    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# =============================================================
# LOGBEACON ADMIN EC2 INSTANCE
# =============================================================

resource "aws_instance" "logbeacon_admin" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = module.vpc.private_subnets[0]

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.logbeacon_admin.id
  ]

  iam_instance_profile = aws_iam_instance_profile.logbeacon_admin.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "logbeacon-admin"
    }
  )
}