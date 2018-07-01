output "vpc_id" {
  value = "${module.instance.vpc_id}"
}

output "subnet_id" {
  value = "${module.instance.subnet_id}"
}

output "bucket_name" {
  value = "${module.s3.bucket_name}"
}

output "public_dns" {
  value = "${module.instance.public_dns}"
}

output "private_dns" {
  value = "${module.instance.private_dns}"
}

output "connect_string" {
  value = "ssh -i data/${var.base_name}.pem ec2-user@${module.instance.public_dns}"
}
