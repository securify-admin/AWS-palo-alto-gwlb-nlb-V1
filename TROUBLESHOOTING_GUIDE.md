# Palo Alto VM-Series GWLB Centralized Inspection Architecture
# Troubleshooting Guide

## Architecture Overview

This deployment implements a centralized inspection architecture using Palo Alto VM-Series firewalls behind a Gateway Load Balancer (GWLB) on AWS. The architecture includes:

- **Security VPC**: Contains Palo Alto VM-Series firewalls, GWLB, and GWLB endpoints
- **Spoke VPCs (A and B)**: Route traffic through a Transit Gateway (TGW) to the Security VPC for inspection
- **Per-AZ routing tables**: Implemented for high availability and reduced cross-AZ data transfer costs
- **IP-based GWLB target registration**: With HTTPS health checks on port 443 and path "/php/login.php"
- **Jumbo frames**: MTU 9192 enabled for better performance
- **Security zones**: Renamed from "trust" to "inspect" and "untrust" to "outside"

## Current Issue: Spoke B Internet Connectivity

The test host in Spoke VPC B cannot ping the internet via the Security VPC. The issue persists despite having:
1. Correct default route (0.0.0.0/0) in Spoke B pointing to the Transit Gateway
2. Correct default route in the Transit Gateway route table pointing to the Security VPC
3. Correct default routes in the Security VPC TGW attachment subnets pointing to GWLB endpoints
4. Default routes in the private dataplane subnets pointing to the firewall's public interfaces
5. Default route in the public dataplane subnet pointing to the Internet Gateway

## Troubleshooting Steps

### 1. Verify GWLB Plugin Configuration on Palo Alto Firewalls

Connect to the management interface of both Palo Alto firewalls and verify the GWLB plugins are enabled:

```
> show plugins
```

Verify that both `aws-gwlb-inspect` and `aws-gwlb-overlay-routing` show as enabled. If not enabled, run:

```
> request plugins aws-gwlb-overlay-routing enable
> request plugins aws-gwlb-inspect enable
```

After enabling the plugins, commit the changes and check if internet connectivity from Spoke B is restored.

### 2. Check Firewall Logs for Dropped Traffic

1. Log in to the Palo Alto firewall web interface
2. Navigate to Monitor > Logs > Traffic
3. Filter for source IP addresses from Spoke B (10.13.0.0/16)
4. Look for any traffic that might be getting dropped or not properly NAT'd

### 3. Verify Symmetric Routing

Ensure that traffic from Spoke B to the internet follows the same path in both directions:

1. Check the route tables in the Security VPC to ensure traffic is flowing through the same AZ in both directions
2. Verify that the GWLB is distributing traffic correctly to the firewalls

### 4. Check MTU Settings

Verify that the MTU settings are consistent across all components:

1. Check the MTU on the test instance in Spoke B
2. Verify that the firewall interfaces have jumbo frames enabled (MTU 9192)
3. Check for any MTU mismatches that might cause packet fragmentation issues

### 5. Verify NAT Configuration on Firewalls

1. Check the NAT rule "Outbound NAT" on the firewalls
2. Ensure it's correctly translating source IPs from the "inspect" zone to the IP of the "outside" interface (ethernet1/2)
3. Verify that the NAT rule is being applied to traffic from Spoke B

### 6. Check Security Policies

1. Verify that the security policies allow traffic from the "inspect" zone to the "outside" zone
2. Ensure that the "Allow outbound" rule is correctly configured and applied

### 7. Verify AWS Route Tables

Double-check all route tables to ensure they're correctly configured:

```bash
# Check Spoke B route table
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=spoke-vpc-b-public-rt" --query "RouteTables[*].Routes[*]"

# Check Transit Gateway route tables
aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id tgw-rtb-0f08025b49429e8a0 --filters "Name=type,Values=static,propagated"
aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id tgw-rtb-09d6a4c8da561bef3 --filters "Name=type,Values=static,propagated"

# Check Security VPC TGW attachment subnet route tables
aws ec2 describe-route-tables --route-table-ids rtb-0181cd0b39fdb4f1f rtb-0bb80325d30ee110f --query "RouteTables[*].Routes[*]"

# Check Security VPC private dataplane subnet route tables
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=security-vpc-private-dataplane-*-rt" --query "RouteTables[*].Routes[*]"

# Check Security VPC public dataplane subnet route table
aws ec2 describe-route-tables --route-table-ids rtb-02af0b611b57cfc31 --query "RouteTables[*].Routes[*]"
```

### 8. Test Connectivity from Firewalls

If possible, log in to the firewalls and test connectivity to the internet:

```
> ping source <interface-ip> host 8.8.8.8
```

This will help determine if the firewalls themselves can reach the internet.

## Instance Type Considerations

Based on previous testing, the following instance types have been evaluated:

1. **c5.2xlarge (8 vCPUs, 16GB RAM)**: Original configuration, works reliably
2. **m5.large (2 vCPUs, 8GB RAM)**: Previously tested, worked with zone name changes
3. **c5.xlarge (4 vCPUs, 8GB RAM)**: Had potential resource constraints but deployment succeeded
4. **m5.xlarge (4 vCPUs, 16GB RAM)**: Failed with EIP association errors

For production deployments, c5.2xlarge appears to be the most reliable choice.

## Backup Information

A complete backup of the Terraform configuration has been created at:
`/Users/anavarro/terraform/palo-aws-poc-v2-backup-20250606/`

This backup includes all the optimizations implemented so far:
- Updated zone names ("inspect" and "outside")
- Per-AZ routing tables for improved availability
- IP-based GWLB target registration with HTTPS health checks
- Jumbo frames (MTU 9192) for better performance

## Next Steps After Resolving the Issue

Once the internet connectivity issue is resolved:

1. Document the root cause and solution
2. Update the Terraform configuration if any manual changes were made
3. Run `terraform plan` to verify that the Terraform state matches the AWS infrastructure
4. Consider implementing automated testing for connectivity between VPCs and to the internet
