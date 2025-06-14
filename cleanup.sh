#!/bin/bash
# Cleanup script for preparing the Terraform project as a GitHub template
# This script removes state files, temporary files, and other artifacts

echo "Cleaning up project for GitHub template..."

# Remove Terraform state files
echo "Removing Terraform state files..."
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform/

# Remove plan files
echo "Removing plan files..."
rm -f plan.out
rm -f tfplan
rm -f *.plan

# Remove workspace files
echo "Removing workspace files..."
rm -f *.code-workspace

# Remove any backup files
echo "Removing backup files..."
find . -name "*.bak" -type f -delete
find . -name "*~" -type f -delete
find . -name "*.swp" -type f -delete

# Remove any .DS_Store files (macOS)
echo "Removing .DS_Store files..."
find . -name ".DS_Store" -type f -delete

# Ensure scripts are executable
echo "Making scripts executable..."
chmod +x *.sh

echo "Cleanup complete! Project is ready for GitHub."
echo "Remember to:"
echo "1. Update the README.md with your project details"
echo "2. Replace architecture_diagram.md with an actual diagram"
echo "3. Review variables.tf and update default values"
echo "4. Create a terraform.tfvars file from the example"
