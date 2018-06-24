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


 $  aws s3api get-object --bucket sse-simple20180624141859497000000002 --key test.txt test.out
 {
     "AcceptRanges": "bytes",
     "ContentType": "text/plain",
     "LastModified": "Sun, 24 Jun 2018 14:31:31 GMT",
     "ContentLength": 865,
     "ETag": "\"1b2e458be5836a269d586bb5da6f42ac\"",
     "ServerSideEncryption": "aws:kms",
     "SSEKMSKeyId": "arn:aws:kms:eu-west-2:889199313043:key/9c2884db-9e89-4053-993d-130009e43f94",
     "Metadata": {}
 }
 [ec2-user@ip-172-60-1-216 ~]$  aws s3api put-object --bucket sse-simple20180624141859497000000002 --key test.out --body test.out
 {
     "SSEKMSKeyId": "arn:aws:kms:eu-west-2:889199313043:key/9c2884db-9e89-4053-993d-130009e43f94",
     "ETag": "\"e5176eeab5415f6df7b511eeca0c63c8\"",
     "ServerSideEncryption": "aws:kms"
 }
