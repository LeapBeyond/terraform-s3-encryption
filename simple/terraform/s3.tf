# ----------------------------------------------------------------------------------------
# our test bucket
# ----------------------------------------------------------------------------------------

resource "aws_s3_bucket" "ssetest" {
  bucket_prefix = "${var.base_name}"
  acl           = "private"
  region        = "${var.aws_region}"
  tags          = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

#
# Note that this policy allows access from the specified role if it's via the VPC endpoint, but
# does NOT deny access based on other criteria. If your account has principals that are allowed
# broad S3 access, they will still be able to read and write the bucket.
# 
resource "aws_s3_bucket_policy" "ssetest" {
  bucket = "${aws_s3_bucket.ssetest.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.testhost.arn}"
      },
      "Action":[
        "s3:GetObject*",
        "s3:PutObject*",
        "s3:DeleteObject*"
      ],
      "Resource": "${aws_s3_bucket.ssetest.arn}/*",
      "Condition" : {
        "StringEquals": {
          "aws:sourceVpce": "${aws_vpc_endpoint.s3endpoint.id}"
        }
      }
    }
  ]
}
POLICY
}
