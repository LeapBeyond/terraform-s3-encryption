# ----------------------------------------------------------------------------------------
# our test bucket
# ----------------------------------------------------------------------------------------

resource "aws_s3_bucket" "ssetest" {
  bucket_prefix = "${var.base_name}"
  acl           = "private"
  region        = "${var.aws_region}"
  tags          = "${merge(map("Name", "${var.base_name}"), var.tags)}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.ssetest.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

#
resource "aws_s3_bucket_policy" "ssetest" {
  bucket = "${aws_s3_bucket.ssetest.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Instance Account Access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.instance_account}"
      },
      "Action":[
        "s3:List*",
        "s3:GetObject*",
        "s3:PutObject*",
        "s3:DeleteObject*"
      ],
      "Resource": ["${aws_s3_bucket.ssetest.arn}", "${aws_s3_bucket.ssetest.arn}/*"]
    }
  ]
}
POLICY
}
