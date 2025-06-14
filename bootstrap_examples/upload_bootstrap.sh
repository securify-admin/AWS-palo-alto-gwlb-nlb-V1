#!/bin/bash
# Script to upload bootstrap files to S3 bucket for Palo Alto VM-Series firewalls

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if bucket name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <s3-bucket-name> [region]"
    echo "Example: $0 my-bootstrap-bucket us-west-2"
    exit 1
fi

BUCKET_NAME=$1
REGION=${2:-us-west-2}  # Default to us-west-2 if not specified

echo "Creating bootstrap directory structure in bucket: $BUCKET_NAME"

# Create the bucket if it doesn't exist
if ! aws s3 ls "s3://$BUCKET_NAME" --region $REGION 2>&1 > /dev/null; then
    echo "Creating bucket $BUCKET_NAME in region $REGION..."
    aws s3 mb "s3://$BUCKET_NAME" --region $REGION
    
    # Enable versioning (recommended for bootstrap buckets)
    aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled --region $REGION
else
    echo "Bucket $BUCKET_NAME already exists."
fi

# Create directory structure
echo "Creating directory structure..."
aws s3api put-object --bucket $BUCKET_NAME --key config/ --region $REGION
aws s3api put-object --bucket $BUCKET_NAME --key content/ --region $REGION
aws s3api put-object --bucket $BUCKET_NAME --key license/ --region $REGION
aws s3api put-object --bucket $BUCKET_NAME --key software/ --region $REGION

# Check if example files exist in the current directory
if [ -f "init-cfg.txt" ]; then
    echo "Uploading init-cfg.txt to s3://$BUCKET_NAME/config/"
    aws s3 cp init-cfg.txt "s3://$BUCKET_NAME/config/" --region $REGION
else
    echo "Warning: init-cfg.txt not found in current directory."
    if [ -f "init-cfg.txt.example" ]; then
        echo "Found init-cfg.txt.example. Would you like to use this file? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Uploading init-cfg.txt.example as init-cfg.txt to s3://$BUCKET_NAME/config/"
            aws s3 cp init-cfg.txt.example "s3://$BUCKET_NAME/config/init-cfg.txt" --region $REGION
        fi
    fi
fi

if [ -f "bootstrap.xml" ]; then
    echo "Uploading bootstrap.xml to s3://$BUCKET_NAME/config/"
    aws s3 cp bootstrap.xml "s3://$BUCKET_NAME/config/" --region $REGION
else
    echo "Warning: bootstrap.xml not found in current directory."
    echo "You will need to create and upload a bootstrap.xml file manually."
    echo "See bootstrap_guide.md for instructions."
fi

echo ""
echo "Bootstrap directory structure created in s3://$BUCKET_NAME/"
echo ""
echo "Next steps:"
echo "1. Ensure you have a valid bootstrap.xml file in s3://$BUCKET_NAME/config/"
echo "2. Update your terraform.tfvars file with:"
echo "   bootstrap_bucket = \"$BUCKET_NAME\""
echo "   bootstrap_key_prefix = \"config/\""
echo ""
echo "For more information, see bootstrap_guide.md"
