# terraform-s3-encryption
Terraform and associated scripts for exploring the use of encryption in S3

The intention of this set of assets is to allow exploration of using strong encryption-at-rest with S3 and AWS managed keys. The end goal is to demonstrate the creation of an S3 bucket that has strong encryption-at-rest and some process (possibly via EMR) that can use the appropriate key(s) to read from the bucket. The bucket should behave as a "dropbox"
