resource "aws_s3_bucket" "ansible_ssm_transfer" {
  bucket = "logbeacon-ansible-ssm-transfer"
}

resource "aws_s3_bucket_versioning" "ansible_ssm_transfer" {
  bucket = aws_s3_bucket.ansible_ssm_transfer.id
  versioning_configuration {
    status = "Disabled" # avoid piling up deleted-but-versioned transfer files
  }
}

