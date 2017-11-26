provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

module "s3-dropbox" {
  source = "./s3-dropbox"
}
