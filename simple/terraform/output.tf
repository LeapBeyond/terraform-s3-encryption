output "vpc_id" {
  value = "${aws_vpc.test_vpc.id}"
}

output "subnet_id" {
  value = "${aws_subnet.ssetest.id}"
}

output "bucket_name" {
  value = "${aws_s3_bucket.ssetest.id}"
}

output "public_dns" {
  value = "${aws_instance.testhost.public_dns}"
}

output "private_dns" {
  value = "${aws_instance.testhost.private_dns}"
}

output "connect_string" {
  value = "ssh -i data/${var.base_name}.pem ec2-user@${aws_instance.testhost.public_dns}"
}
