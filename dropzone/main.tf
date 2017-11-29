# --------------------------------------------------------------------------------------------------------------
# various data lookups
# --------------------------------------------------------------------------------------------------------------
data "aws_ami" "target_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["${var.dropzone_ami_name}"]
  }
}

# TODO: move this out
data "aws_vpc" "defaultvpc" {
  cidr_block = "172.31.0.0/16"
}

data "aws_iam_policy_document" "ec2-service-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# TODO: parameterise that nacl
variable "default_network_acl_id" {
  default = "acl-6c6a2f05"
}

# --------------------------------------------------------------------------------------------------------------
# lock down the default security group and NACL
# --------------------------------------------------------------------------------------------------------------

resource "aws_default_security_group" "default" {
  vpc_id = "${data.aws_vpc.defaultvpc.id}"

  tags {
    Name    = "default_sg"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_default_network_acl" "support" {
  default_network_acl_id = "${var.default_network_acl_id}"

  tags {
    Name    = "default_nacl"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the dropzone VPC
# --------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "dropzone_vpc" {
  cidr_block           = "${var.dropzone_vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "dropzone-vpc"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_internet_gateway" "dropzone-gateway" {
  vpc_id = "${aws_vpc.dropzone_vpc.id}"

  tags {
    Name    = "dropzone-gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the dropzone subnet
# --------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "dropzone_subnet" {
  vpc_id                  = "${aws_vpc.dropzone_vpc.id}"
  cidr_block              = "${var.dropzone_subnet_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name    = "dropzone-subnet"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# ------------------------ route table associated with the subnet ----------------------------
resource "aws_route_table" "dropzone-rt" {
  vpc_id = "${aws_vpc.dropzone_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dropzone-gateway.id}"
  }

  tags {
    Name    = "dropzone-rt"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_route_table_association" "dropzone-rta" {
  subnet_id      = "${aws_subnet.dropzone_subnet.id}"
  route_table_id = "${aws_route_table.dropzone-rt.id}"
}

# ------------------------ security groups --------------------------------------------------------

resource "aws_security_group" "dropzone_ssh" {
  name        = "dropzone_ssh"
  description = "allows ssh access to dropzone"
  vpc_id      = "${aws_vpc.dropzone_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.dropzone_ssh_inbound}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "dropzone_default" {
  vpc_id = "${aws_vpc.dropzone_vpc.id}"

  tags {
    Name    = "dropzone_default"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# ------------------------ IAM role for dropzone instance -------------------------------------------------

resource "aws_iam_role" "dropzone_role" {
  name_prefix           = "dropzone"
  path                  = "/"
  description           = "roles polices the dropzone can use"
  force_detach_policies = true
  assume_role_policy    = "${data.aws_iam_policy_document.ec2-service-role-policy.json}"
}

resource "aws_iam_instance_profile" "dropzone_profile" {
  name_prefix = "dropzone"
  role        = "${aws_iam_role.dropzone_role.name}"
}

# ------------------------ dropzone Instance --------------------------------------------------------

resource "aws_instance" "dropzone" {
  ami                    = "${data.aws_ami.target_ami.id}"
  instance_type          = "${var.dropzone_instance_type}"
  key_name               = "${var.dropzone_key}"
  subnet_id              = "${aws_subnet.dropzone_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.dropzone_ssh.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.dropzone_profile.name}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  tags {
    Name    = "dropzone"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  volume_tags {
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  provisioner "file" {
    source      = "${path.root}/../data/${var.secure_key}.pem"
    destination = "/home/${var.dropzone_user}/.ssh/${var.secure_key}.pem"

    connection {
      type        = "ssh"
      user        = "${var.dropzone_user}"
      private_key = "${file("${path.root}/../data/${var.dropzone_key}.pem")}"
      timeout     = "5m"
    }
  }
}

resource "null_resource" "update" {
  connection {
    type        = "ssh"
    agent       = false
    user        = "${var.dropzone_user}"
    host        = "${aws_instance.dropzone.public_dns}"
    private_key = "${file("${path.root}/../data/${var.dropzone_key}.pem")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "mkdir ~/.aws ~/bin && cd ~/bin && wget https://releases.hashicorp.com/terraform/0.10.7/terraform_0.10.7_linux_amd64.zip && unzip terraform*zip",
      "aws configure set region ${var.aws_region}",
      "aws configure set output json",
      "chmod 0400 /home/${var.dropzone_user}/.ssh/${var.secure_key}.pem",
    ]
  }
}
