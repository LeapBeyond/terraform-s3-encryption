# SSE example

This is a basic example around using S3 SSE (Server Side Encryption). We will create two groups, and a user in each group.
One group is privileged, and can read encrypted data from the bucket, the other cannot read. Both groups can write data into
the bucket.

It is assumed that:
 - the AWS CLI is available
 - appropriate AWS credentials are available
 - terraform is available
 - the scripts are being run on a unix account.

 ## To use
 Copy the `env.rc.template` to `env.rc` and fill in the blanks. Be careful not to commit the actual `env.rc` to git!

 Assuming that you have your profile setup correctly in `.aws` and that profile has appropriate (very broad) privileges,
 then just execute the `sse-example.sh` script then ...
