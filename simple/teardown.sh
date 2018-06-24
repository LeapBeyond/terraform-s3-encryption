#!/bin/bash

cd `dirname $0`
[[ -s ./env.rc ]] && source ./env.rc


# echo "======== emptying buckets ========"
#
# for BUCKET in $(aws s3api list-buckets --output table --query 'Buckets[*].Name' | grep s3ec2test | sed -e 's/ //g' -e 's/|//g')
# do
#   aws s3 rm s3://$BUCKET --recursive
# done

echo "======= terraform destroy ======="

cd terraform
terraform init
terraform destroy -force \
  -var "aws_region=$AWS_DEFAULT_REGION" \
  -var "aws_profile=$AWS_PROFILE" \
  -var "base_name=$BASE_NAME" \
  -var "inbound_cidr=$CIDR"
cd ..

echo "======= removing key pair ======="
aws ec2 delete-key-pair --key-name $BASE_NAME > /dev/null 2>&1
rm -f data/$BASE_NAME.pem > /dev/null 2>&1
