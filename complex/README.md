# terraform-s3-encryption/complex

These scripts are used to demonstrate a reasonably common desire: S3 buckets in one account accessed by an EC2 instance from another, with server-side encryption in play. In order to use this, you will of course need two distinct AWS accounts. In one account we will set up the bucket and encryption key, and relevant roles and permissions, and in the other we will set up an EC2 instance in it's own VPC. As discussed in the `simple` set, it's not a bad practice to throw up a VPC for instances to live in - if you have that habit, it's more natural to use VPC within an account to partition responsibility and access.

## Usage
There are two wrapper scripts that setup and tear down the assets. These assume that you are running from a unix-like environment (they were tested with MacOS), and that there are credentials available granting a pretty high - preferably full administration - access to the target AWS account. They also assume that you have a recent version of  [Terraform](https://terraform.io) installed, and the AWS CLI.

To use the scripts, first copy `env.rc.template` to `env.rc` and replace values as required:

| Value | Purpose |
| ----- | ------ |
| AWS_INSTANCE_PROFILE | the name of the profile to use for the account holding the EC2 instance|
| AWS_S3_PROFILE | the name of the profile to use for the account holding the S3 bucket |
| AWS_DEFAULT_REGION | the identifier of the AWS region to build into |
| BASE_NAME | a string used as the basis for names of things - you may as well not change this |
| CIDR | the CIDR block specifying addresses from which you want to be able to SSH into the instance |

After setting that up, executing `./setup.sh` should create an SSH key in the `data` directory, setup the assets, and copy a file into the S3 bucket. Various useful pieces of information will be output, including instructions on how to SSH to the instance, e.g.

```
Outputs:

bucket_name = sse-complex20180701105917997600000001
connect_string = ssh -i data/sse-complex.pem ec2-user@ec2-35-177-122-71.eu-west-2.compute.amazonaws.com
private_dns = ip-172-60-1-250.eu-west-2.compute.internal
public_dns = ec2-35-177-122-71.eu-west-2.compute.amazonaws.com
subnet_id = subnet-0a84e6ce16ab23f9d
vpc_id = vpc-03e203d54cbe600de
```

You should be able to SSH onto the target host, then use the AWS CLI on that host to fetch and put files into the bucket. This will indicate that SSE is in place, although you may also like to examine the files and bucket through the AWS console. Note the output for the two `head-object` calls - the object we have copied up using the `bucket-owner-full-control` ACL remains owned by the source account, rather than the account holding the S3 bucket.

```
$ ssh -i data/sse-complex.pem ec2-user@ec2-35-177-122-71.eu-west-2.compute.amazonaws.com

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

## Notes
There are two main modules in the Terraform set, one for each of the accounts. There's also a tiny module `account` which is used as helper to fetch the account ID for the accounts - the S3 account needs to know the ID of the Instance account.

Most of the `instance` module is the same as in the `simple` case - it sets up a VPC with subnet, NACL, route table etc, and launches the EC2 instance inside the desired subnet. Refer to the notes on the `simple` case for further discussions of what is set up and why. The only key difference is in `security.tf`, where we assign policies to the instance which:

  - allow access to the specified bucket using the ARN of the bucket
  - access to the KMS encryption key using the key's ARN

The other half of the permissions is set in the `s3` set, where we have two parts:

  - a policy on the bucket allowing the instance _account_ to access the bucket. Note that the permissions in the role on the instance can be no more permissive than this policy;
  - a policy on the KMS key allowing the instance _account_ to use the key. Again, the role cannot have more permissions than are stated here.

It is important to note that the EC2 instance is not [adopting a role](https://www.parttimepolymath.net/masthead/archives/814) in the S3 account to gain access to the resources. Instead, the resources have policies allowing the instance account to use them, and the EC2 instance role has specified permissions.

It is difficult to say whether using policies on the target resources is better or worse than assuming a role in the target environment, although it is worth noting that not all resources can have policies attached and for those you would probably need to assume a role in the target. One advantage of putting the policy directly on the resource is that you can rest assured that the EC2 instance can only use the "remote" resources that have been specifically permitted.
