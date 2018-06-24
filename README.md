# terraform-s3-encryption
Terraform and associated scripts for exploring the use of encryption in S3

## Rationale

Being able to persist data in S3 with strong encryption is a very attractive option on top of controlling access to the contents of buckets.

## Goal

The intention of this set of assets is to allow exploration of using strong encryption-at-rest with S3 and AWS managed keys. The end goal is to demonstrate the creation of an S3 bucket that has strong encryption-at-rest and an EC2 instance that can use the appropriate key(s) to read from the bucket. There is a "simple" case demonstrated, with all assets in a single AWS account, and a "complex" case, where the S3 bucket is in a different account to the EC2 instance.

## Usage

Refer to the README.md in each of the sub directories for more information.

## Useful references

The following is a collection of materials around S3 policies in general, and some about S3 and encryption

 - <https://aws.amazon.com/blogs/big-data/process-encrypted-data-in-amazon-emr-with-amazon-s3-and-aws-kms/>
 - <https://aws.amazon.com/blogs/big-data/encrypt-your-amazon-redshift-loads-with-amazon-s3-and-aws-kms/>
 - <https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/>
 - <http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html>
 - <http://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html>
 - <https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html>

