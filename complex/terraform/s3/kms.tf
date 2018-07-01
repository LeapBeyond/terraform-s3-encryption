data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ssetest" {
  deletion_window_in_days = 7
  tags                    = "${merge(map("Name", "${var.base_name}"), var.tags)}"
  description             = "Key for SSE in S3 for ssetest"

  policy = <<Policy
{
  "Version": "2012-10-17",
  "Id": "${var.base_name}",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow instance account to use key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.instance_account}:root"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${var.instance_account}:root"
        ]
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
Policy
}

resource "aws_kms_alias" "ssetest" {
  name          = "alias/ssetest"
  target_key_id = "${aws_kms_key.ssetest.id}"
}
