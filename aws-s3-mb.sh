# ! /bin/bash
# Script to create two S3 buckets as needed for project-mcgruff
# jamegill@cisco.com 20240923 "lightly tested, ymmv"

# See where we are
echo "Gathering AWS account \c"
AWS_ACCT_NUMB=`aws sts get-caller-identity --query "Account" --output text`
echo "number ${AWS_ACCT_NUMB}, and name \c"
AWS_ACCT_NAME=`aws iam list-account-aliases --query "AccountAliases" --max-items 1 --output text`
echo "${AWS_ACCT_NAME}"

# User-defined variables
read -p "Username (or another valid string) to make S3 bucket names unique: [$USER]  " userName
USER_NAME=${userName:-${USER}}
DATE_SUFFIX=$(date +%Y%m%d%H%M%S)

# Bucket base names
BUCKET_BASE_NAME1="project-mcgruff-terraform-files"
BUCKET_BASE_NAME2="project-mcgruff-jumphost-logfiles"

# Full bucket names with unique suffixes
#BUCKET_NAME1="${BUCKET_BASE_NAME1}-${USER_NAME}-${DATE_SUFFIX}"
#BUCKET_NAME2="${BUCKET_BASE_NAME2}-${USER_NAME}-${DATE_SUFFIX}"
BUCKET_NAME1="${BUCKET_BASE_NAME1}-${USER_NAME}"
BUCKET_NAME2="${BUCKET_BASE_NAME2}-${USER_NAME}"

# Verify before taking action
echo " Ready to create two S3 buckets in acct ${AWS_ACCT_NUMB}, ${AWS_ACCT_NAME}."
echo "  The 1st bucket will be called: ${BUCKET_NAME1}"
echo "  The 2nd bucket will be called: ${BUCKET_NAME2}"
read -n 1 -s -r -p " ..... Press any key to continue, ctrl-c to bail. "
echo; echo;

# Create the S3 buckets
# All S3 buckets are global, region does not need to be a variable here
# The aws s3 mb command does not error if the bucket already exists.
aws s3 mb s3://$BUCKET_NAME1 --region us-east-1
[ $? -eq 0 ] && echo " If ${BUCKET_NAME1} didn't exist before, it does now." || echo " Bucket 1 creation failed."
aws s3 mb s3://$BUCKET_NAME2 --region us-east-1
[ $? -eq 0 ] && echo " If ${BUCKET_NAME2} didn't exist before, it does now." || echo " Bucket 2 creation failed."

echo;
echo               " Next we will edit the provider.tf files in this project to use those buckets"
read -n 1 -s -r -p " ..... Press any key to continue, ctrl-c to bail."
echo; echo

# Use sed to replace the bucket names in the Terraform files
sed -i.orig  "s/bucket = \".*\"/bucket = \"$BUCKET_NAME1\"/" terraform/1_infrastructure/provider.tf
sed -i.orig  "s/bucket = \".*\"/bucket = \"$BUCKET_NAME1\"/" terraform/2_application/provider.tf
sed -i.orig  "s/s3_bucket_name = \".*\"/s3_bucket_name = \"$BUCKET_NAME2\"/" terraform/1_infrastructure/3_jump_host.tf

echo; echo " Done, verifying ..."
grep --recursive $BUCKET_NAME1 *
grep --recursive $BUCKET_NAME2 *

echo; echo "That is all.  Thank you for using $0"