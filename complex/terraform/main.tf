module "account" {
  source = "./account"
  providers = {
    aws = "aws.instance"
  }
}

module "instance" {
  source = "./instance"

  providers = {
    aws = "aws.instance"
  }

  aws_region   = "${var.aws_region}"
  base_name    = "${var.base_name}"
  inbound_cidr = "${var.inbound_cidr}"
  tags         = "${var.tags}"
  bucket_arn   = "${module.s3.bucket_arn}"
}

module "s3" {
  source = "./s3"

  providers = {
    aws = "aws.s3"
  }

  instance_account = "${module.account.account_id}"
  aws_region = "${var.aws_region}"
  base_name  = "${var.base_name}"
  tags       = "${var.tags}"
}
