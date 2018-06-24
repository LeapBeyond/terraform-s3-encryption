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
#  NACL for the test subnet
# ----------------------------------------------------------------------------------------

resource "aws_network_acl" "ssetest" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  subnet_ids = ["${aws_subnet.ssetest.id}"]
  tags       = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

# accept SSH requests inbound
resource "aws_network_acl_rule" "ssh_in" {
  network_acl_id = "${aws_network_acl.ssetest.id}"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.inbound_cidr}"
  from_port      = 22
  to_port        = 22
}

# allow responses to SSH requests outbound
resource "aws_network_acl_rule" "ephemeral_out" {
  network_acl_id = "${aws_network_acl.ssetest.id}"
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.inbound_cidr}"
  from_port      = 1024
  to_port        = 65535
}

# allow YUM and AWS API requests outbound
resource "aws_network_acl_rule" "https_out" {
  network_acl_id = "${aws_network_acl.ssetest.id}"
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# accept responses to YUM and API requests inbound
resource "aws_network_acl_rule" "ephemeral_in" {
  network_acl_id = "${aws_network_acl.ssetest.id}"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
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

resource "aws_iam_role_policy_attachment" "s3access" {
  role       = "${aws_iam_role.testhost.name}"
  policy_arn = "${aws_iam_policy.s3access.arn}"
}

resource "aws_iam_instance_profile" "testhost" {
  name = "${aws_iam_role.testhost.name}"
  role = "${aws_iam_role.testhost.id}"
}
