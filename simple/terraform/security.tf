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
        "s3:Get*",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.ssetest.arn}",
        "${aws_s3_bucket.ssetest.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "testhost" {
  role       = "${aws_iam_role.testhost.name}"
  policy_arn = "${aws_iam_policy.testhost.arn}"
}

resource "aws_iam_instance_profile" "testhost" {
  name = "${aws_iam_role.testhost.name}"
  role = "${aws_iam_role.testhost.id}"
}
