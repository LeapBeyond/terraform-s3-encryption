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
