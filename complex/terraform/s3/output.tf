output "bucket_name" {
  value = "${aws_s3_bucket.ssetest.id}"
}

output "bucket_arn" {
  value = "${aws_s3_bucket.ssetest.arn}"
}
