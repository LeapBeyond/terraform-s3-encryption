output "dropzone_public_dns" {
  value = "${aws_instance.dropzone.public_dns}"
}

output "dropzone_private_dns" {
  value = "${aws_instance.dropzone.private_dns}"
}

output "connect_string" {
  value = "ssh -i ${var.dropzone_key}.pem ${var.dropzone_user}@${aws_instance.dropzone.public_dns}"
}

output "dropzone_subnet_cidr" {
  value = "${var.dropzone_subnet_cidr}"
}

output "dropzone_vpc_id" {
  value = "${aws_vpc.dropzone_vpc.id}"
}

output "dropzone_subnet_id" {
  value = "${aws_subnet.dropzone_subnet.id}"
}

output "dropzone_ssh_sg_id" {
  value = "${aws_security_group.dropzone_ssh.id}"
}

output "dropzone_rt_id" {
  value = "${aws_route_table.dropzone-rt.id}"
}

output "project_tags" {
  value = "${var.tags}"
}
