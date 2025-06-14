#!/bin/bash
# Script to check environment prerequisites for deploying the Palo Alto VM-Series architecture

echo "Checking environment prerequisites..."
echo "===================================="

# Check Terraform version
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "✓ Terraform installed: version $TF_VERSION"
    
    # Check if version is at least 1.0.0
    if [[ "$(echo -e "1.0.0\n$TF_VERSION" | sort -V | head -n1)" == "1.0.0" || "$TF_VERSION" == "1.0.0" ]]; then
        echo "  ✓ Terraform version meets minimum requirement (>= 1.0.0)"
    else
        echo "  ✗ WARNING: Terraform version is below 1.0.0. Please upgrade to 1.0.0 or higher."
    fi
else
    echo "✗ Terraform not found. Please install Terraform >= 1.0.0"
    echo "  See: https://learn.hashicorp.com/tutorials/terraform/install-cli"
fi

echo ""

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    echo "✓ AWS CLI installed: version $AWS_VERSION"
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
        AWS_USER=$(aws sts get-caller-identity --query "Arn" --output text)
        echo "  ✓ AWS credentials configured"
        echo "  • AWS Account: $AWS_ACCOUNT"
        echo "  • AWS User: $AWS_USER"
    else
        echo "  ✗ AWS credentials not configured or invalid"
        echo "  • Run 'aws configure' to set up your credentials"
    fi
else
    echo "✗ AWS CLI not found. Please install the AWS CLI"
    echo "  See: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
fi

echo ""

# Check for key pair
if [ -f "terraform.tfvars" ]; then
    KEY_NAME=$(grep key_name terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
    if [ ! -z "$KEY_NAME" ]; then
        echo "• Key pair name in terraform.tfvars: $KEY_NAME"
        
        # Try to check if key pair exists in AWS
        if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
            if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
                echo "  ✓ Key pair '$KEY_NAME' exists in AWS"
            else
                echo "  ✗ Key pair '$KEY_NAME' not found in AWS"
                echo "  • Create it with: aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem"
                echo "  • Then: chmod 400 $KEY_NAME.pem"
            fi
        fi
    else
        echo "• Key pair name not found in terraform.tfvars"
        echo "  • Make sure to set 'key_name' in terraform.tfvars"
    fi
else
    echo "• terraform.tfvars not found"
    echo "  • Copy terraform.tfvars.example to terraform.tfvars and customize it"
fi

echo ""

# Check for bootstrap bucket
if [ -f "terraform.tfvars" ]; then
    BUCKET_NAME=$(grep bootstrap_bucket terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
    if [ ! -z "$BUCKET_NAME" ]; then
        echo "• Bootstrap bucket in terraform.tfvars: $BUCKET_NAME"
        
        # Try to check if bucket exists in AWS
        if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
            if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
                echo "  ✓ Bucket '$BUCKET_NAME' exists in AWS"
                
                # Check for bootstrap files
                if aws s3 ls "s3://$BUCKET_NAME/config/init-cfg.txt" &> /dev/null; then
                    echo "  ✓ init-cfg.txt found in bucket"
                else
                    echo "  ✗ init-cfg.txt not found in bucket"
                    echo "  • Use bootstrap_examples/upload_bootstrap.sh to set up your bootstrap bucket"
                fi
                
                if aws s3 ls "s3://$BUCKET_NAME/config/bootstrap.xml" &> /dev/null; then
                    echo "  ✓ bootstrap.xml found in bucket"
                else
                    echo "  ✗ bootstrap.xml not found in bucket"
                    echo "  • See bootstrap_guide.md for instructions on creating bootstrap.xml"
                fi
            else
                echo "  ✗ Bucket '$BUCKET_NAME' not found in AWS"
                echo "  • Use bootstrap_examples/upload_bootstrap.sh to create the bucket and upload files"
            fi
        fi
    else
        echo "• Bootstrap bucket not found in terraform.tfvars"
        echo "  • Make sure to set 'bootstrap_bucket' in terraform.tfvars"
    fi
fi

echo ""
echo "===================================="
echo "Environment check complete"
