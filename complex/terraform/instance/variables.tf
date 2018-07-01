variable "aws_region" {}
variable "base_name" {}
variable "inbound_cidr" {}
variable "bucket_arn" {}
variable "key_arn" {}

variable "tags" {
  type = "map"
}

variable "vpc_cidr" {
  default = "172.60.0.0/16"
}

variable "ami_name" {
  default = "amzn2-ami-hvm-2017.12.0.20180509-x86_64-gp2"
}

variable "root_vol_size" {
  default = 8
}

variable "instance_type" {
  default = "t2.micro"
}

data "aws_ip_ranges" "s3ip" {
  regions  = ["${var.aws_region}"]
  services = ["s3"]
}

data "aws_ip_ranges" "s3ip-useast1" {
  regions  = ["us-east-1"]
  services = ["s3"]
}

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
