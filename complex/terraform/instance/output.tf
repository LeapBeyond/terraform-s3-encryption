output "vpc_id" {
  value = "${aws_vpc.test_vpc.id}"
}

output "subnet_id" {
  value = "${aws_subnet.ssetest.id}"
}

output "public_dns" {
  value = "${aws_instance.testhost.public_dns}"
}

output "private_dns" {
  value = "${aws_instance.testhost.private_dns}"
}
