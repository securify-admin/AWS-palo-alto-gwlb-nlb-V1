#!/bin/bash
# Script to validate Terraform configuration before deployment

echo "Validating Terraform configuration..."
echo "===================================="

# Initialize Terraform if .terraform directory doesn't exist
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Run terraform validate
echo "Running terraform validate..."
if terraform validate; then
    echo "✓ Terraform configuration is valid"
else
    echo "✗ Terraform configuration has errors"
    exit 1
fi

echo ""

# Check for required variables in terraform.tfvars
echo "Checking terraform.tfvars for required variables..."
if [ ! -f "terraform.tfvars" ]; then
    echo "✗ terraform.tfvars file not found"
    echo "  • Copy terraform.tfvars.example to terraform.tfvars and customize it"
    exit 1
fi

# Check for key variables
REQUIRED_VARS=("aws_region" "key_name" "bootstrap_bucket" "fw_ami_id")
MISSING_VARS=0

for VAR in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "$VAR" terraform.tfvars; then
        echo "✗ Required variable '$VAR' not found in terraform.tfvars"
        MISSING_VARS=1
    fi
done

# Check key_name specifically
KEY_NAME=$(grep key_name terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
if [ "$KEY_NAME" == "your-key-pair-name" ] || [ "$KEY_NAME" == "palo-poc-key-pair" ]; then
    echo "✗ Default key pair name detected: '$KEY_NAME'"
    echo "  • Please update with your actual EC2 key pair name"
    MISSING_VARS=1
fi

# Check bootstrap_bucket specifically
BUCKET_NAME=$(grep bootstrap_bucket terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
if [[ "$BUCKET_NAME" == *"UNIQUE"* ]] || [[ "$BUCKET_NAME" == *"your-bootstrap"* ]]; then
    echo "✗ Default bootstrap bucket name detected: '$BUCKET_NAME'"
    echo "  • Please update with your actual S3 bucket name"
    MISSING_VARS=1
fi

if [ $MISSING_VARS -eq 0 ]; then
    echo "✓ All required variables found in terraform.tfvars"
fi

echo ""

# Run terraform plan (optional)
echo "Would you like to run 'terraform plan' to preview changes? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Running terraform plan..."
    terraform plan
fi

echo ""
echo "===================================="
echo "Validation complete"

if [ $MISSING_VARS -eq 1 ]; then
    echo "⚠️  Please fix the issues above before deploying"
    exit 1
else
    echo "✅ Configuration looks good! You can proceed with 'terraform apply'"
fi
