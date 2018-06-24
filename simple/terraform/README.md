# terraform-s3-encryption/simple
Terraform and associated scripts for exploring the use of encryption in S3


## Usage

Refer to the README.md in each of the sub directories for more information.


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
