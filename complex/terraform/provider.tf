# provider "aws" {
#   region  = "${var.aws_region}"
#   profile = "${var.aws_instance_profile}"
# }

provider "aws" {
  alias   = "instance"
  region  = "${var.aws_region}"
  profile = "${var.aws_instance_profile}"
}

provider "aws" {
  alias   = "s3"
  region  = "${var.aws_region}"
  profile = "${var.aws_s3_profile}"
}
