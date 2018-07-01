module "instance" {
  source = "./instance"

  providers = {
    aws = "aws.instance"
  }

  aws_region   = "${var.aws_region}"
  base_name    = "${var.base_name}"
  inbound_cidr = "${var.inbound_cidr}"
  tags         = "${var.tags}"
}

module "s3" {
  source = "./s3"

  providers = {
    aws = "aws.s3"
  }

  aws_region = "${var.aws_region}"
  base_name  = "${var.base_name}"
  tags       = "${var.tags}"
}
