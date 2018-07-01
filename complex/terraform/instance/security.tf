# ----------------------------------------------------------------------------------------
# seal off the default NACL
# ----------------------------------------------------------------------------------------
resource "aws_default_network_acl" "test_default" {
  default_network_acl_id = "${aws_vpc.test_vpc.default_network_acl_id}"
  tags                   = "${merge(map("Name", "${var.base_name}-default"), var.tags)}"
}

# seal off the default security group
resource "aws_default_security_group" "test_default" {
  vpc_id = "${aws_vpc.test_vpc.id}"
  tags   = "${merge(map("Name", "${var.base_name}-default"), var.tags)}"
}

# ----------------------------------------------------------------------------------------
# setup instance profile
# ----------------------------------------------------------------------------------------
resource "aws_iam_role" "testhost" {
  name        = "${var.base_name}"
  description = "privileges for the test instance"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "testhost" {
  name        = "${var.base_name}"
  description = "allow access to specific bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:List*",
        "s3:GetObject*",
        "s3:PutObject*",
        "s3:DeleteObject*"
      ],
      "Resource": [
        "${var.bucket_arn}",
        "${var.bucket_arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "use_kms" {
  name        = "${var.base_name}-use-kms"
  description = "allow use of encryption key from other account"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:RevokeGrant",
        "kms:CreateGrant",
        "kms:ListGrants"
      ],
      "Resource": "${var.key_arn}",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": true
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:DescribeKey"
      ],
      "Resource": "${var.key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:ReEncryptTo",
        "kms:ReEncryptFrom"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "testhost" {
  role       = "${aws_iam_role.testhost.name}"
  policy_arn = "${aws_iam_policy.testhost.arn}"
}

resource "aws_iam_role_policy_attachment" "use_kms" {
  role       = "${aws_iam_role.testhost.name}"
  policy_arn = "${aws_iam_policy.use_kms.arn}"
}

resource "aws_iam_instance_profile" "testhost" {
  name = "${aws_iam_role.testhost.name}"
  role = "${aws_iam_role.testhost.id}"
}
