# ----------------------------------------------------------------------------------------
# setup a VPC containing a single subnet, with an internet gateway, and a route table
# to send traffic to and from the subnet via that gateway. Note also the use of the S3 VPC endpoint
# ----------------------------------------------------------------------------------------
resource "aws_vpc" "test_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

resource "aws_subnet" "ssetest" {
  vpc_id                  = "${aws_vpc.test_vpc.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 8, 1)}"
  map_public_ip_on_launch = true
  tags                    = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

resource "aws_internet_gateway" "ssetest" {
  vpc_id = "${aws_vpc.test_vpc.id}"
  tags   = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

resource "aws_route_table" "ssetest" {
  vpc_id = "${aws_vpc.test_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ssetest.id}"
  }

  tags = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

resource "aws_route_table_association" "ssetest" {
  subnet_id      = "${aws_subnet.ssetest.id}"
  route_table_id = "${aws_route_table.ssetest.id}"
}

resource "aws_vpc_endpoint" "s3endpoint" {
  vpc_id          = "${aws_vpc.test_vpc.id}"
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = ["${aws_route_table.ssetest.id}"]
}

# ----------------------------------------------------------------------------------------
# NACL to attach to the test subnet
# ----------------------------------------------------------------------------------------
resource "aws_network_acl" "ssetest" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  subnet_ids = ["${aws_subnet.ssetest.id}"]
  tags       = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}

# accept SSH requets inbound
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

# allow YUM and AWS requests outbound
resource "aws_network_acl_rule" "http_out" {
  network_acl_id = "${aws_network_acl.ssetest.id}"
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# accept responses to YUM and AWS requests inbound
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
