# ----------------------------------------------------------------------------------------
# setup an EC2 instance
# ----------------------------------------------------------------------------------------
data "aws_ami" "target_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
}

resource "aws_instance" "testhost" {
  ami           = "${data.aws_ami.target_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.base_name}"
  subnet_id     = "${aws_subnet.ssetest.id}"

  vpc_security_group_ids = [
    "${aws_security_group.testhost.id}",
  ]

  iam_instance_profile = "${aws_iam_instance_profile.testhost.name}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  tags        = "${merge(map("Name","s3ec2test"), var.tags)}"
  volume_tags = "${var.tags}"

  user_data = <<EOF
#!/bin/bash
yum update -y -q
EOF
}

resource "aws_security_group" "testhost" {
  vpc_id      = "${aws_vpc.test_vpc.id}"
  name_prefix = "${var.base_name}"
  description = "Limited SSH in and https/http out"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.inbound_cidr}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["52.95.0.0/16"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_ip_ranges.s3ip.cidr_blocks}", "${data.aws_ip_ranges.s3ip-useast1.cidr_blocks}"]
  }

  tags = "${merge(map("Name", "${var.base_name}"), var.tags)}"
}
