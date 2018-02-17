#!/bin/bash

cd `dirname $0`
[[ -s ./env.rc ]] && source ./env.rc

echo "======= setting up groups ======="
for GROUP in sseprivileged sseordinary
do
  aws iam create-group --group-name $GROUP
  aws iam attach-group-policy --group-name $GROUP --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
done

echo "======= setting up users ======="
aws iam create-user --user-name alice
aws iam create-user --user-name betty
aws iam add-user-to-group --group-name sseprivileged --user-name alice
aws iam add-user-to-group --group-name sseordinary --user-name betty

echo "======= setting up encryption key ======="
KEY_ID=$(aws kms create-key --origin AWS_KMS --query KeyMetadata.KeyId)

echo "======= teearing down encryption key ======="
aws kms schedule-key-deletion --key-id $KEY_ID

echo "======= tearing down users ======="
aws iam remove-user-from-group --group-name sseprivileged --user-name alice
aws iam remove-user-from-group --group-name sseordinary --user-name betty
aws iam delete-user --user-name alice
aws iam delete-user --user-name betty

echo "======= tearing down groups ======="
for GROUP in sseprivileged sseordinary
do
  aws iam detach-group-policy --group-name $GROUP --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  aws iam delete-group --group-name $GROUP
done
