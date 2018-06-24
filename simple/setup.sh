#!/bin/bash

cd `dirname $0`
[[ -s ./env.rc ]] && source ./env.rc

echo "======= setting up key pair ======="
aws ec2 describe-key-pairs --output text --key-name $BASE_NAME >/dev/null 2>&1
if [ $? -gt 0 ]
then
  aws ec2 create-key-pair --key-name $BASE_NAME --query 'KeyMaterial' | sed -e 's/^"//' -e 's/"$//' -e's/\\n/\
/g'> data/$BASE_NAME.pem
  chmod 400 data/$BASE_NAME.pem
fi
aws ec2 describe-key-pairs --output text --key-name $BASE_NAME

echo "======== applying terraform ========"
cd terraform
terraform init
terraform apply -auto-approve \
  -var "aws_region=$AWS_DEFAULT_REGION" \
  -var "aws_profile=$AWS_PROFILE" \
  -var "base_name=$BASE_NAME" \
  -var "inbound_cidr=$CIDR"
cd ..

# echo "======== populating buckets ========"
#
# for BUCKET in $(aws s3api list-buckets --output table --query 'Buckets[*].Name' | grep s3ec2test | sed -e 's/ //g' -e 's/|//g')
# do
#   aws s3 cp data/test.txt s3://$BUCKET/test.txt
# done
