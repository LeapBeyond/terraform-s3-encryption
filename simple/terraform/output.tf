output "vpc_id" {
  value = "${aws_vpc.test_vpc.id}"
}

output "subnet_id" {
  value = "${aws_subnet.ssetest.id}"
}

output "bucket_name" {
  value = "${aws_s3_bucket.ssetest.id}"
}
