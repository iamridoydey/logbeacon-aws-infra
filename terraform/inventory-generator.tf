# =============================================================
#              ANSIBLE INVENTORY FILE
# =============================================================

resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.module}/templates/inventory.tpl",
    {
      instance_id     = aws_instance.logbeacon_admin.id
      ssm_bucket_name = aws_s3_bucket.ansible_ssm_transfer.bucket
      aws_region      = var.default_region
    }
  )

  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
}