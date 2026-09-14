resource "aws_iam_policy" "secret_kms_decrypt" {
  name = "logbeacon-secrets-kms-decrypt"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DecryptSecretsManagerSecrets"
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = aws_kms_key.logbeacon_kms_key.arn

        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.default_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "secret_kms_read_write" {
  name = "logbeacon-secrets-kms-write"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EncryptAndDecryptSecretsManagerSecrets"
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]

        Resource = aws_kms_key.logbeacon_kms_key.arn

        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.default_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}