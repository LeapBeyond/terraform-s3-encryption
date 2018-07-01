# terraform-s3-encryption/simple

These scripts setup a S3 bucket with SSE (server side encryption) enabled, and an EC2 instance that is able to read/write with that bucket. There's a reasonable amount of subtlety in this, and some efforts made to demonstrate good security practices that I will talk through below.

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
bucket_name = sse-simple20180624141859497000000002
connect_string = ssh -i data/sse-simple.pem ec2-user@ec2-18-130-152-82.eu-west-2.compute.amazonaws.com
private_dns = ip-172-60-1-216.eu-west-2.compute.internal
public_dns = ec2-18-130-152-82.eu-west-2.compute.amazonaws.com
subnet_id = subnet-040b1b9c4ad53bba0
vpc_id = vpc-00a0f2acf393cbe7b
```

You should be able to SSH onto the target host, then use the AWS CLI on that host to fetch and put files into the bucket. This will indicate that SSE is in place, although you may also like to examine the files and bucket through the AWS console:

```
$ ssh -i data/sse-simple.pem ec2-user@ec2-18-130-152-82.eu-west-2.compute.amazonaws.com

[ec2-user@ip-172-60-1-216 ~]$ aws s3api get-object --bucket sse-simple20180624141859497000000002 --key test.txt test.out
{
    "AcceptRanges": "bytes",
    "ContentType": "text/plain",
    "LastModified": "Sun, 24 Jun 2018 14:31:31 GMT",
    "ContentLength": 865,
    "ETag": "\"1b2e458be5836a269d586bb5da6f42ac\"",
    "ServerSideEncryption": "aws:kms",
    "SSEKMSKeyId": "arn:aws:kms:eu-west-2:130438891993:key/9c2884db-9e89-4053-993d-130009e43f94",
    "Metadata": {}
}

[ec2-user@ip-172-60-1-216 ~]$ aws s3api put-object --bucket sse-simple20180624141859497000000002 --key test.out --body test.out
{
    "SSEKMSKeyId": "arn:aws:kms:eu-west-2:130438891993:key/9c2884db-9e89-4053-993d-130009e43f94",
    "ETag": "\"e5176eeab5415f6df7b511eeca0c63c8\"",
    "ServerSideEncryption": "aws:kms"
}

[ec2-user@ip-172-60-1-216 ~]$  exit

$
```

When you are done with the assets, execute `./teardown.sh` to remove them all.

## Explanations and Notes
The terraform assets are all held within the `terraform` folder, and execution will result in use of local terraform state in that folder (demonstrating use of shared state in S3 and DynamoDB is beyond the scope of this example). There are quite a few files for such a relatively small environment, but that was done in order to keep each file small and understandable, and to group related actions:

| File | Purpose |
| ---- | ------- |
| variables.tf | specifies various constants, which should not need to be altered |
| provider.tf  | specifies how to connect to AWS |
| network.tf | creates the "network" layer, encompassing the VPC, subnet, routing tables and NACL |
| security.tf | sets up the EC2 instance profile role |
| s3.tf | sets up the S3 bucket |
| kms.tf | sets up the encryption key |
| instance.tf | specifies the EC2 instance and the security group attached to it |
| output.tf | writes things of interest to the console |

This demonstration is framed to illustrate several security best practices, in particular

 - granting access to data to an EC2 instance, and not to users
 - limiting inbound and outbound traffic for the instance
 - constraining bucket access

There are best practices, which I will discuss as we go along, and try to indicate where there are risks.

The overall set of assets that are setup are pretty complete:

 - VPC
 - routing table
 - internet gateway
 - S3 VPC Endpoint gateway
 - Subnet
 - NACL for the Subnet
 - EC2 instance
 - Security Group for the instance
 - IAM Role and Instance profile for the instance
 - KMS key
 - S3 bucket with SSE enabled

Note of course for a full fledged system, CloudTrail, VPC Flow Logs and S3 object logging should be added, at a minimum.

### network.tf
Building fresh infrastructure into a fresh VPC is a good way to prevent inheriting existing network and security problems (as long as you are aware that not all assets are associated with a VPC). It also allows creation of precise and simple routing tables. Ideally the EC2 instance would reach the Internet via a NAT gateway, which is not done here. Going a little further, ideally the EC2 instance is placed in a subnet that does not allow public IP addresses, and the instance reached - if needed - via some sort of bastion or jump host.

SSH connections in, and the responses back out, are limited to the desired CIDR blocks. Similarly, HTTP out is limited to the CIDR block used by the AWS Yum repositories, however we have opened up the ephemeral range for responses to come from anywhere, as HTTPS (intended for use by calls to the AWS API) is also allowed out to anywhere. A refinement here would be to constrain 443 out (and the responses back in) to just the CIDR blocks used by the S3 API.

This file also sets up the VPC Endpoint for S3 - this is useful when constraining access on the S3 bucket and by denying all access if requests do not originate through the VPC Endpoint, you can lock down access through the console. Be careful with this - you can easily specify that access is only via the VPC Endpoint, then find yourself unable to configure or delete the bucket later.

Note that we are creating a specific route table and attaching it to the subnet. If this is not done, the subnet just inherits the default route table in the VPC. This is dangerous, as changes to this route table can easily alter desired behaviour for the subnet unintentionally. A useful best practice is to remove route table entries from the default route table, and then not use it for anything.

### security.tf
The first part illustrates another useful best practice - Terraform can "take over" the default security group and default NACL for the VPC. By not specifying any rules, they both reduce to "deny all traffic from/to everywhere". Then if these are ever used accidentally, you will not accidentally open up traffic you thought was closed.

The rest of the file is creating the role and profile to be used by the EC2 instance. This is strongly limited to just the desired S3 API calls - it's always best to limit access as much as possible up front, and open up later if you need to.

Of interest is that we do not need to specify that the role has access to KMS or the KMS key. This is one of the nice features of the way in which SSE has been implemented: KMS is called on the principal's behalf by S3, and the principal does not itself need to call the KMS API. You will see below the other part of this is that the KMS Key has a policy indicating which principal's can use it.

### s3.tf
The specification to use SSE is very simple, as you can see. The bucket policy is a bit more complicated, even if it looks very simple, as S3 bucket policies are themselves complicated. While at first glance it looks like this policy locks down the bucket to very narrow access, that's not entirely the case. By specifying a policy, then attempts to work against the bucket have to not match any of the "deny" statements, and match one of the "allow" statements. Where it gets complicated is:

  - by specifying a policy, what is not allowed is denied
  - a principal that has a privilege that "beats" the policy will still have access.

This last bit is the one that will bite you - any principal that (for example) allows `s3:*` to `*` will have read/write access to the bucket regardless of what is specified in this policy. You need to be particularly careful with the Amazon managed policies: quite a few of them allow this very broad S3 access. The policy here works for our example, as (apart from any pre-existing principals in your account), only the administrator and the instance have read/write access to the bucket.

Locking down the bucket further is beyond the scope of this demonstration at this time, although I may come back and tighten this up later.

### kms.tf
This sets up the KMS encyption key. The configuration of the key itself is pretty simple, but do note that we are setting a description, creating an alias and assigning tags - failure to do this can make it impossible to tell keys apart in the console. The policy is a little more interesting, as it grants access to use IAM principals, and then grants the required privileges just to the EC2 instance role. A caveat though - as with S3 privileges, a principal with broader access (e.g. having access to all keys) can override this constraint. This is useful for our example though, as it allows the administrator account used to execute Terraform access to the key when uploading test data.

Again, note that there is a three-cornered arrangement required: the EC2 instance needs to be allowed to use S3, S3 is configured to use a particular key by default, and KMS checks that the ultimate caller (EC2) is allowed to use the key.

### instance.tf
The EC2 instance itself is trivial - we're using a recent Amazon Linux 2 instance because it's got the AWS CLI on it and is reasonably up to date. Note though that the first thing we do during provisioning is a `yum update`. Looking back at the `network.tf` file (and the security group here), you will note that we allow HTTP requests out to a specific CIDR block, which encompasses the internal AWS Yum repositories. The Security Group attached to the instance largely mirrors the NACL attached to the subnet we are launching in, and strictly speaking we could probably drop the NACLs, however using both is another useful safety measure in case an instance is launched with an over-open security group.

Outgoing requests in this security group are more constrained than the NACL - we are limiting outgoing HTTPS requests on 443 to just the published CIDR blocks for the S3 API, which makes it useful that the EC2 instance does not need to directly call the KMS API. At first glance this looks like a really good security measure, but it comes with a huge drawback - only the whitelisted APIs can be called. If you go down this route, be aware that you will not be able to use Systems Manager or Inspector to manage the instance, and you potentially block off access to other useful API endpoints.
