# AWS Palo Alto VM-Series Centralized Inspection Architecture on AWS

This Terraform project deploys a Palo Alto VM-Series centralized inspection architecture on AWS, featuring a security VPC with VM-Series firewalls, Gateway Load Balancer (GWLB), and Application Load Balancer (ALB), connected to spoke VPCs via Transit Gateway.

## Architecture Overview

This architecture provides:

- **Centralized Security Inspection**: All traffic (north-south and east-west) is inspected by Palo Alto VM-Series firewalls
- **Scalable Firewall Deployment**: Gateway Load Balancer enables easy scaling of firewall capacity
- **High Availability**: Deployment across multiple availability zones ensures resilience
- **Simplified Network Architecture**: Transit Gateway provides a hub-and-spoke model for inter-VPC communication
- **Flexible Traffic Patterns**: Supports both inbound traffic (via ALB) and outbound/east-west traffic (via GWLB)
- **Variable-Based Routing Control**: Toggle between direct internet access and Transit Gateway routing for Web VPC

## Modular Design

This project uses a modular design approach with the following modules:

- **vpc**: Creates VPCs, subnets, and related networking components
  - Security VPC with management, dataplane, and TGW attachment subnets
  - Spoke VPCs with application subnets
  - Web VPC with private subnets for web servers

- **firewall**: Deploys Palo Alto VM-Series firewalls
  - Bootstrap configuration from S3 bucket
  - Three interfaces: management, public, and private
  - Security groups for each interface

- **gwlb**: Sets up Gateway Load Balancer and endpoints
  - GWLB in the Security VPC
  - GWLB Endpoints in dedicated subnets
  - Target group registration for VM-Series firewalls

- **alb**: Creates Application Load Balancer for web traffic
  - Deployed in private subnets
  - Listeners for HTTP/HTTPS
  - Target group registration for web servers

- **tgw**: Configures Transit Gateway and attachments

## Enterprise Deployment with Terraform Cloud and GitHub

This project is configured for enterprise-level deployment using Terraform Cloud and GitHub:

### GitHub Integration

1. **Repository**: The code is hosted at [https://github.com/securify-admin/AWS-palo-alto-gwlb-nlb-V1.git](https://github.com/securify-admin/AWS-palo-alto-gwlb-nlb-V1.git)

2. **Workflow**:
   - Use feature branches for changes
   - Create pull requests for code reviews
   - Merge approved changes to main branch

### Terraform Cloud Setup

1. **Configure Workspace**:
   - Create a new workspace in Terraform Cloud
   - Connect to the GitHub repository
   - Set execution mode to "Remote"

2. **Configure Variables**:
   - Add AWS credentials as sensitive environment variables:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
   - Add Terraform variables:
     - `route_web_vpc_through_tgw` (boolean) - Controls Web VPC routing
     - `key_name` - EC2 key pair name (default: "palo-poc-key-pair")

3. **Update backend.tf**:
   - Modify the `backend.tf` file with your organization and workspace names

## Variable-Based Routing Control

This project implements a variable-based approach to control Web VPC routing:

- **Initial Deployment** (`route_web_vpc_through_tgw = false`):
  - Web VPC has direct internet access via Internet Gateway
  - Web servers can access the internet for package installation
  - Default routes (0.0.0.0/0) in Web VPC point to Internet Gateway

- **Post-Deployment Configuration** (`route_web_vpc_through_tgw = true`):
  - All Web VPC traffic routes through Transit Gateway
  - Traffic is inspected by Palo Alto VM-Series firewalls in Security VPC
  - More secure configuration for production use

## Deployment Workflow

1. **Initial Setup**:
   - Push code to GitHub repository
   - Configure Terraform Cloud workspace
   - Set `route_web_vpc_through_tgw = false` for initial deployment
   - Run Terraform apply to deploy infrastructure
   - Web servers can access internet for package installation

2. **Production Configuration**:
   - After web servers are fully set up
   - Change `route_web_vpc_through_tgw` to `true` in Terraform Cloud
   - Run Terraform apply to update routing
   - All traffic now routes through Transit Gateway for inspection
  - Central Transit Gateway with route tables
  - Attachments for all VPCs
  - Routes for inter-VPC communication

- **alb**: Deploys Application Load Balancer for web servers
  - Deployed in Web VPC
  - Target group registration for web servers
  - Security groups for web traffic

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform v1.0.0 or newer
3. AWS CLI installed and configured
4. EC2 Key Pair (default name: `securify-key-pair`)

## Deployment Instructions

### 1. AWS CLI Configuration

Create an AWS IAM user with programmatic access and appropriate permissions:

1. Go to AWS IAM console and create a new user
2. Attach the `AdministratorAccess` policy (for testing only; use more restrictive policies for production)
3. Generate access key and secret key
4. Configure AWS CLI:

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your preferred region (e.g., us-west-2)
# Enter your preferred output format (e.g., json)
```

### 2. Prepare Key Pair

Create an EC2 key pair if you don't already have one:

```bash
aws ec2 create-key-pair --key-name securify-key-pair --query 'KeyMaterial' --output text > securify-key-pair.pem
chmod 400 securify-key-pair.pem
```

### 3. Customize Configuration

1. Clone this repository
2. Modify the following variables in `variables.tf`:
   - `bootstrap_bucket`: Change to a globally unique S3 bucket name (current: `palo-bootstrap-494825111641`)
   - `key_name`: Change to your EC2 key pair name if different from `securify-key-pair`
   - `region`: Change to your preferred AWS region if needed
   - `fw_instance_type`: Adjust if you need a different VM-Series instance size

### 4. Deploy the Infrastructure

Run the following commands from the project root directory:

```bash
# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply -auto-approve
```

The deployment will take approximately 15-20 minutes to complete.

## Bootstrap Configuration

The Terraform code automatically creates and configures the S3 bucket with the necessary bootstrap files. The bootstrap configuration includes:

1. **S3 Bucket Structure**:
   ```
   /
   ├── config/
   │   ├── bootstrap.xml      # Main configuration file
   │   └── init-cfg.txt       # Initial configuration parameters
   ├── content/               # Empty directory for content updates
   ├── license/               # Empty directory for license files
   └── software/              # Empty directory for PAN-OS updates
   ```

2. **Key Bootstrap Settings**:
   - Interface swap enabled (`mgmt-interface-swap` in init-cfg.txt)
   - Security rules with proper UUIDs
   - NAT rules for outbound traffic
   - Basic security configuration

3. **Important Notes**:
   - The bootstrap.xml file contains the initial configuration for the firewalls
   - The S3 bucket is configured with a VPC endpoint for secure access
   - IAM roles and policies are created to allow the firewalls to access the bootstrap files

## Post-Deployment

After successful deployment:

1. **Access the Firewalls**:
   - Use the management IPs from the Terraform output: `terraform output palo_alto_firewall_management_ips`
   - Access via HTTPS: https://<management-ip>
   - Default credentials: admin/admin (change immediately)

2. **Verify Interface Configuration**:
   - Confirm interface mapping is correct:
     - ethernet1/1: Private dataplane interface (connected to GWLB)
     - ethernet1/2: Public dataplane interface
     - Management: Dedicated management interface

3. **Verify Security Rules**:
   - Confirm the security rules are properly committed
   - Check that NAT rules are functioning correctly

4. **Test Traffic Flows**:
   - East-West: Test communication between resources in different Spoke VPCs
   - North-South: Test outbound internet access from resources in Spoke VPCs
   - Inbound: Test access to applications via the public IPs

## Testing

### 1. Verify Firewall Initialization

```bash
# Get the management IPs of the firewalls
terraform output palo_alto_firewall_management_ips

# Get the public IPs of the firewalls
terraform output palo_alto_firewall_public_ips
```

Access the firewalls via HTTPS and verify they have initialized correctly without commit errors.

### 2. Test Traffic Flows

#### East-West Traffic
- SSH into one of the Windows servers in Spoke VPC A
- Try to ping or connect to the Windows server in Spoke VPC B
- Check the traffic logs in the firewall to verify inspection

```bash
# Get Windows server IPs
terraform output windows_server_private_ips
terraform output windows_server_public_ips
```

#### Outbound Traffic
- SSH into one of the Windows servers
- Try to access the internet (e.g., ping google.com)
- Verify the traffic is being NATed through the firewall's public interface

#### Inbound Traffic
- Get the GWLB endpoint service name
```bash
terraform output gwlb_endpoint_service_name
```
- Verify applications in the Spoke VPCs are accessible through the firewall

## Troubleshooting

### Common Issues

1. **Firewall Bootstrap Issues**
   - Check S3 bucket permissions
   - Verify bootstrap.xml syntax is correct
   - Check IAM role permissions for the firewall instances
   - SSH to the firewall and check `/var/log/bootstrap.log`

2. **Connectivity Issues**
   - Verify Transit Gateway route tables are correctly configured
   - Check security groups and NACLs
   - Verify GWLB endpoints are correctly deployed
   - Check firewall rules and NAT configuration

3. **XML Validation Errors**
   - Ensure all security and NAT rules have valid UUIDs
   - Remove any unsupported configuration elements
   - Check for proper XML structure and closing tags

### Debugging Commands

```bash
# Check firewall status
ssh admin@<management-ip>
> show system info
> show interface all

# Check S3 bucket contents
aws s3 ls s3://<bootstrap-bucket-name> --recursive

# Check Transit Gateway route tables
aws ec2 describe-transit-gateway-route-tables --region <region>
```

## Clean Up

To destroy the infrastructure:

```bash
# Destroy all resources
terraform destroy -auto-approve

# If you encounter issues with resource dependencies, you can target specific resources first
terraform destroy -target=module.firewall.aws_instance.palo_fw -auto-approve
terraform destroy -auto-approve
```

## Notes

- The deployment creates a dedicated S3 bucket for bootstrap configuration
- Interface swap is enabled to align AWS network interfaces with Palo Alto interface expectations
- The architecture follows a true centralized inspection model with all traffic inspected by firewalls in the Security VPC
- The configuration uses BYOL (Bring Your Own License) VM-Series images
# Updated documentation
