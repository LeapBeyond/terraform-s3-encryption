variable "aws_region" {}
variable "dropzone_key" {}
variable "secure_key" {}

variable "dropzone_ssh_inbound" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "dropzone_user" {
  default = "ec2-user"
}

variable "dropzone_ami_name" {
  default = "amzn-ami-hvm-2017.09.0.20170930-x86_64-ebs"
}

variable "dropzone_instance_type" {
  default = "t2.micro"
}

# 172.18.0.0 - 172.18.255.255
variable "dropzone_vpc_cidr" {
  default = "172.18.0.0/16"
}

# 172.18.10.0 - 172.18.10.63
variable "dropzone_subnet_cidr" {
  default = "172.18.10.0/26"
}

variable "root_vol_size" {
  default = 10
}
