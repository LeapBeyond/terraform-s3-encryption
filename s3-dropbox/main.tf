# --------------------------------------------------------------------------------------------------------------
# define s3 bucket: my-test-dropbox
# --------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "bucket" {
  bucket = "my-test-dropbox"
  acl    = "private"

  tags {
    Name        = "my-test-dropbox"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = "${aws_s3_bucket.bucket.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "my-test-dropbox-policy",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-test-dropbox/*",
      "Condition": {
         "IpAddress": {"aws:SourceIp": "78.16.253.52/32"}
      }
    }
  ]
}
POLICY
}

# Notes:
# AIM or S3 policy - https://aws.amazon.com/blogs/security/iam-policies-and-bucket-policies-and-acls-oh-my-controlling-access-to-s3-resources/
# We can grant specific users access instead of source IP but defining one or more principals instead of Sid and Condition with a list of IPs.

# --------------------------------------------------------------------------------------------------------------
# define SQS Queue for new file notifications
# --------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue" "queue" {
  name = "s3-dropbox-new-file"

  tags {
    Name        = "dropbox-new-file"
    Environment = "Dev"
  }

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-dropbox-new-file",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.bucket.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.bucket.id}"

  queue {
    queue_arn = "${aws_sqs_queue.queue.arn}"
    events    = ["s3:ObjectCreated:*"]
  }
}

# --------------------------------------------------------------------------------------------------------------
# define KMS Master Key and alias
# --------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "key" {
  description = "s3 master key"
}

resource "aws_kms_alias" "key" {
  name          = "alias/s3-master-key"
  target_key_id = "${aws_kms_key.key.key_id}"
}
