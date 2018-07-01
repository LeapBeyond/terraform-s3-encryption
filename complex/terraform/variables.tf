variable "aws_region" {}
variable "aws_instance_profile" {}
variable "aws_s3_profile" {}

variable "base_name" {
  description = "string used to base various names on"
}

variable "inbound_cidr" {
  description = "permitted source of SSH connections into instance"
}

variable "tags" {
  default = {
    "project" = "terraform-s3-encryption/complex"
    "client"  = "Internal"
  }
}
