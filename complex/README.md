# terraform-s3-encryption/complex

These scripts are used to demonstrate a reasonably common desire: S3 buckets in one account accessed by an EC2 instance from another, with server-side encryption in play. In order to use this, you will of course need two distinct AWS accounts. In one account we will set up the bucket and encryption key, and relevant roles and permissions, and in the other we will set up an EC2 instance in it's own VPC. As discussed in the `simple` set, it's not a bad practice to throw up a VPC for instances to live in - if you have that habit, it's more natural to use VPC within an account to partition responsibility and access.

## Usage
There are two wrapper scripts that setup and tear down the assets. These assume that you are running from a unix-like environment (they were tested with MacOS), and that there are credentials available granting a pretty high - preferably full administration - access to the target AWS account. They also assume that you have a recent version of  [Terraform](https://terraform.io) installed, and the AWS CLI.

To use the scripts, first copy `env.rc.template` to `env.rc` and replace values as required:

| Value | Purpose |
| ----- | ------ |
| AWS_PROFILE | the name of the profile to use |
| AWS_DEFAULT_REGION | the identifier of the AWS region to build into |
| BASE_NAME | a string used as the basis for names of things - you may as well not change this |
| CIDR | the CIDR block specifying addresses from which you want to be able to SSH into the instance |

After setting that up, executing `./setup.sh` should create an SSH key in the `data` directory, setup the assets, and copy a file into the S3 bucket. Various useful pieces of information will be output, including instructions on how to SSH to the instance, e.g.


```
[ec2-user@ip-172-60-1-250 ~]$ aws s3 ls s3://sse-complex20180701105917997600000001/
2018-07-01 13:13:15    1665194 test.txt

[ec2-user@ip-172-60-1-250 ~]$ aws s3 cp s3://sse-complex20180701105917997600000001/test.txt test.txt
download: s3://sse-complex20180701105917997600000001/test.txt to ./test.txt

[ec2-user@ip-172-60-1-250 ~]$ aws s3 cp test.txt s3://sse-complex20180701105917997600000001/new.txt --acl bucket-owner-full-control
upload: ./test.txt to s3://sse-complex20180701105917997600000001/new.txt

[ec2-user@ip-172-60-1-250 ~]$ aws s3api list-objects --bucket sse-complex20180701105917997600000001
{
    "Contents": [
        {
            "LastModified": "2018-07-01T13:14:00.000Z",
            "ETag": "\"32182eaa06673c8a153b9faadc3b9ce0\"",
            "StorageClass": "STANDARD",
            "Key": "new.txt",
            "Owner": {
                "ID": "81b0fd234b0c35d681cbf13a585e1153f03cb4973f5b0127339c967ddb452de9"
            },
            "Size": 1665194
        },
        {
            "LastModified": "2018-07-01T13:13:15.000Z",
            "ETag": "\"1a49376f5072af711246cd754b553ed5\"",
            "StorageClass": "STANDARD",
            "Key": "test.txt",
            "Owner": {
                "ID": "737568a64d46d38cc60898ad8dc9551e5a257b2caf877b05c3faf4a09a835e23"
            },
            "Size": 1665194
        }
    ]
}

[ec2-user@ip-172-60-1-250 ~]$ aws s3api head-object --bucket sse-complex20180701105917997600000001 --key test.txt
{
    "AcceptRanges": "bytes",
    "ContentType": "text/plain",
    "LastModified": "Sun, 01 Jul 2018 13:13:15 GMT",
    "ContentLength": 1665194,
    "ETag": "\"1a49376f5072af711246cd754b553ed5\"",
    "ServerSideEncryption": "aws:kms",
    "SSEKMSKeyId": "arn:aws:kms:eu-west-2:358115407625:key/3c641d51-eb50-4370-8951-cd8413ab93f4",
    "Metadata": {}
}

[ec2-user@ip-172-60-1-250 ~]$ aws s3api head-object --bucket sse-complex20180701105917997600000001 --key new.txt
{
    "AcceptRanges": "bytes",
    "ContentType": "text/plain",
    "LastModified": "Sun, 01 Jul 2018 13:14:00 GMT",
    "ContentLength": 1665194,
    "ETag": "\"32182eaa06673c8a153b9faadc3b9ce0\"",
    "ServerSideEncryption": "aws:kms",
    "SSEKMSKeyId": "arn:aws:kms:eu-west-2:358115407625:key/3c641d51-eb50-4370-8951-cd8413ab93f4",
    "Metadata": {}
}
```
