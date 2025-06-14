# Centralized AWS Inspection Architecture Deployment Guide

This guide explains how to deploy the Palo Alto VM-Series centralized inspection architecture in a new AWS region or account, with a focus on the critical routing configurations needed for proper traffic inspection.

## Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                              AWS Cloud (us-west-2)                                |
|                                                                                   |
|  +---------------------+           +---------------------+                         |
|  |                     |           |                     |                         |
|  |    Spoke VPC A      |           |    Spoke VPC B      |                         |
|  |   (10.12.0.0/16)    |           |   (10.13.0.0/16)    |                         |
|  |                     |           |                     |                         |
|  | +----------------+  |           | +----------------+  |                         |
|  | |  App Subnets   |  |           | |  App Subnets   |  |                         |
|  | | 10.12.0.0/24   |  |           | | 10.13.0.0/24   |  |                         |
|  | | 10.12.1.0/24   |  |           | | 10.13.1.0/24   |  |                         |
|  | +-------+--------+  |           | +-------+--------+  |                         |
|  |         |           |           |         |           |                         |
|  |         | TGW       |           |         | TGW       |                         |
|  |         | Attachment|           |         | Attachment|                         |
|  +---------|-----------|------+    +---------|-----------|------+                 |
|            |           |                     |           |                         |
|            +-----|-----+                     +-----|-----+                         |
|                  |                                 |                               |
|                  |                                 |                               |
|                  v                                 v                               |
|         +------------------+  Spoke RT  +------------------+                       |
|         |                  |<--------->|                  |                       |
|         |  Transit Gateway |            |  Transit Gateway |                       |
|         |  (TGW)           |<--------->|  Route Tables    |                       |
|         |                  |  Security |                  |                       |
|         +--------|---------+    RT     +------------------+                       |
|                  |                                                                |
|                  | TGW Attachment                                                 |
|                  v                                                                |
|  +-------------------------------------------------------------+                 |
|  |                                                             |                 |
|  |                     Security VPC (10.11.0.0/16)             |                 |
|  |                                                             |                 |
|  |  +----------------+  +----------------+  +----------------+ |                 |
|  |  | TGW Attachment |  |  GWLB Subnets  |  |  Management   | |                 |
|  |  |    Subnets     |  |                |  |    Subnets    | |                 |
|  |  | 10.11.6.0/24   |  | 10.11.2.0/24   |  | 10.11.0.0/24  | |                 |
|  |  | 10.11.7.0/24   |  | 10.11.3.0/24   |  | 10.11.1.0/24  | |                 |
|  |  +-------+--------+  +-------+--------+  +-------+--------+ |                 |
|  |          |                   |                   |           |                 |
|  |          v                   v                   |           |                 |
|  |  +-------+-------------------+-------+          |           |                 |
|  |  |                                   |          |           |                 |
|  |  |     Gateway Load Balancer         |<---------+           |                 |
|  |  |     (GWLB)                        |                      |                 |
|  |  |                                   |                      |                 |
|  |  +----------------+------------------+                      |                 |
|  |                   |                                         |                 |
|  |                   v                                         |                 |
|  |  +----------------+------------------+     +---------------+-+                |
|  |  |                                   |     |                 |                |
|  |  |   Palo Alto VM-Series Firewalls   |<--->|  Public Subnets |                |
|  |  |   (in GWLB Subnets)               |     | 10.11.4.0/24   |                |
|  |  |                                   |     | 10.11.5.0/24   |                |
|  |  +-----------------------------------+     +-----------------+                |
|  |                                                                               |
|  +---------------------------------------------------------------+               |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

### Key Components

#### VPCs and Subnets

1. **Security VPC (10.11.0.0/16)**
   - Management Subnets: 10.11.0.0/24, 10.11.1.0/24
     - Purpose: Firewall management interfaces
   - GWLB Subnets: 10.11.2.0/24, 10.11.3.0/24
     - Purpose: Firewall dataplane interfaces and GWLB endpoints
   - Public Dataplane Subnets: 10.11.4.0/24, 10.11.5.0/24
     - Purpose: Public-facing firewall interfaces for outbound/inbound traffic
   - TGW Attachment Subnets: 10.11.6.0/24, 10.11.7.0/24
     - Purpose: Transit Gateway attachment points

2. **Spoke VPC A (10.12.0.0/16)**
   - App Subnets: 10.12.0.0/24, 10.12.1.0/24
     - Purpose: Application workloads

3. **Spoke VPC B (10.13.0.0/16)**
   - App Subnets: 10.13.0.0/24, 10.13.1.0/24
     - Purpose: Application workloads

#### Transit Gateway Configuration

1. **Transit Gateway (TGW)**
   - Central hub for all VPC traffic
   - Appliance Mode enabled for symmetric routing

2. **TGW Route Tables**
   - **Spoke Route Table**
     - Associated with: Spoke VPC A and Spoke VPC B attachments
     - Routes all traffic to Security VPC attachment
     - No route propagation from Security VPC
   - **Security Route Table**
     - Associated with: Security VPC attachment
     - Routes traffic back to spoke VPCs
     - Propagates routes from spoke VPCs

#### Gateway Load Balancer (GWLB)

1. **GWLB**
   - Distributes traffic across Palo Alto firewalls
   - Located in Security VPC GWLB subnets

2. **GWLB Endpoints**
   - Service insertion points for traffic inspection
   - Located in Security VPC GWLB subnets
   - Target for traffic from TGW attachment subnets

#### Palo Alto VM-Series Firewalls

1. **Firewall Interfaces**
   - Management Interface (eth1/AWS eth1): Connected to Management Subnets
   - Private Dataplane Interface (eth0/AWS eth0): Connected to GWLB Subnets
   - Public Dataplane Interface (eth2/AWS eth2): Connected to Public Subnets

2. **Bootstrap Configuration**
   - Stored in S3 bucket
   - Interface swap enabled

### Detailed Routing Configuration

#### 1. TGW Attachment Subnet Route Table (Security VPC)

| Destination    | Target                | Purpose                                      |
|----------------|----------------------|----------------------------------------------|
| 10.11.0.0/16   | Local                | Local Security VPC traffic                   |
| 10.12.0.0/16   | GWLB Endpoint        | Route Spoke A traffic to firewall inspection |
| 10.13.0.0/16   | GWLB Endpoint        | Route Spoke B traffic to firewall inspection |
| 0.0.0.0/0      | Internet Gateway     | Default route for internet traffic           |

#### 2. GWLB Subnet Route Table (Security VPC)

| Destination    | Target                | Purpose                                      |
|----------------|----------------------|----------------------------------------------|
| 10.11.0.0/16   | Local                | Local Security VPC traffic                   |
| 10.12.0.0/16   | Transit Gateway      | Return Spoke A traffic to TGW after inspection |
| 10.13.0.0/16   | Transit Gateway      | Return Spoke B traffic to TGW after inspection |
| 0.0.0.0/0      | Internet Gateway     | Default route for internet traffic           |

#### 3. TGW Spoke Route Table

| Destination    | Target                | Purpose                                      |
|----------------|----------------------|----------------------------------------------|
| 10.12.0.0/16   | Security VPC Attachment | Route Spoke A traffic through Security VPC |
| 10.13.0.0/16   | Security VPC Attachment | Route Spoke B traffic through Security VPC |
| 0.0.0.0/0      | Security VPC Attachment | Default route through Security VPC         |

#### 4. TGW Security Route Table

| Destination    | Target                | Purpose                                      |
|----------------|----------------------|----------------------------------------------|
| 10.12.0.0/16   | Spoke A Attachment    | Route traffic back to Spoke A                |
| 10.13.0.0/16   | Spoke B Attachment    | Route traffic back to Spoke B                |

#### 5. Spoke VPC Route Tables

| Destination    | Target                | Purpose                                      |
|----------------|----------------------|----------------------------------------------|
| Local CIDR     | Local                | Local VPC traffic                            |
| 10.11.0.0/16   | Transit Gateway      | Route to Security VPC through TGW            |
| Other Spoke CIDR| Transit Gateway      | Route to other Spoke VPCs through TGW        |
| 0.0.0.0/0      | Transit Gateway      | Default route through TGW                    |

### Traffic Flow Examples

#### 1. East-West Traffic (Spoke A to Spoke B)

1. Traffic from Spoke A (10.12.0.0/16) destined for Spoke B (10.13.0.0/16)
2. Spoke A route table sends traffic to Transit Gateway
3. TGW Spoke route table forwards traffic to Security VPC attachment
4. Security VPC TGW attachment subnet receives traffic
5. TGW attachment subnet route table forwards traffic to GWLB endpoint
6. GWLB endpoint sends traffic to Palo Alto firewall for inspection
7. Firewall inspects and returns traffic to GWLB
8. Traffic returns to TGW attachment subnet
9. Traffic is forwarded to Transit Gateway
10. TGW Security route table forwards traffic to Spoke B attachment
11. Traffic arrives at Spoke B

#### 2. Outbound Traffic (Spoke to Internet)

1. Traffic from Spoke VPC destined for internet (0.0.0.0/0)
2. Spoke route table sends traffic to Transit Gateway
3. TGW Spoke route table forwards traffic to Security VPC attachment
4. Security VPC TGW attachment subnet receives traffic
5. TGW attachment subnet route table forwards traffic to GWLB endpoint
6. GWLB endpoint sends traffic to Palo Alto firewall for inspection
7. Firewall inspects and sends traffic out through public interface
8. Traffic exits through Internet Gateway to the internet

## Critical Components for Redeployment

### 1. Transit Gateway Route Tables Configuration

The Transit Gateway (TGW) is the central hub for all traffic. Proper route table configuration is essential:

#### TGW Spoke Route Table
- **Purpose**: Routes traffic from spoke VPCs to the Security VPC for inspection
- **Critical Settings**:
  - Static routes for all spoke VPC CIDRs pointing to the Security VPC attachment
  - Default route (0.0.0.0/0) pointing to the Security VPC attachment
  - Set `blackhole = false` for all static routes
  - **IMPORTANT**: Disable route propagation from Security VPC to spoke route table to prevent direct spoke-to-spoke routing

#### TGW Security Route Table
- **Purpose**: Routes return traffic from Security VPC back to the appropriate spoke VPC
- **Critical Settings**:
  - Static routes for each spoke VPC CIDR pointing to the respective spoke VPC attachment
  - Enable route propagation from spoke VPCs to Security VPC route table

### 2. Security VPC Route Tables

#### TGW Attachment Subnet Route Table
- **Purpose**: Routes traffic from TGW to GWLB endpoints for inspection
- **Critical Settings**:
  - **MOST CRITICAL**: Routes for all spoke VPC CIDRs must point to the GWLB endpoint, NOT to the Transit Gateway
  - If routes are pointing to TGW instead of GWLB endpoint, traffic will bypass inspection
  - Manual fix if needed:
    ```bash
    aws ec2 replace-route --route-table-id <rtb-id> --destination-cidr-block <spoke-cidr> --vpc-endpoint-id <gwlbe-id> --region <region>
    ```

#### GWLB Subnet Route Table
- **Purpose**: Routes post-inspection traffic back to TGW
- **Critical Settings**:
  - Routes for all spoke VPC CIDRs pointing to the Transit Gateway

### 3. Spoke VPC Route Tables

- **Purpose**: Routes traffic to other VPCs through TGW
- **Critical Settings**:
  - Routes for all other VPC CIDRs (including Security VPC) pointing to the Transit Gateway
  - Local routes for the VPC's own CIDR block

## Deployment Steps

1. **Update Variable Values in variables.tf**
   - **AWS Region**: Change `aws_region` (default: "us-west-2")
   ```hcl
   variable "aws_region" {
     description = "AWS region to deploy resources"
     type        = string
     default     = "us-west-2"  # Change to your target region
   }
   ```
   
   - **Availability Zones**: Update `availability_zones` to match your region
   ```hcl
   variable "availability_zones" {
     description = "List of AZs to use for the deployment"
     type        = list(string)
     default     = ["us-west-2a", "us-west-2b"]  # Change to your region's AZs
   }
   ```
   
   - **VPC CIDRs**: Modify if needed to avoid overlapping with existing networks
   ```hcl
   variable "security_vpc_cidr" {
     description = "CIDR block for Security VPC"
     type        = string
     default     = "10.11.0.0/16"  # Change if needed
   }
   
   variable "spoke_vpc_cidrs" {
     description = "List of CIDR blocks for Spoke VPCs"
     type        = list(string)
     default     = ["10.12.0.0/16", "10.13.0.0/16"]  # Change if needed
   }
   ```
   
   - **Key Pair**: Update `key_name` to your EC2 key pair name
   ```hcl
   variable "key_name" {
     description = "EC2 Key pair name for VM-Series instances"
     type        = string
     default     = "securify-key-pair"  # Change to your key pair name
   }
   ```

2. **Bootstrap Bucket Configuration**
   - Create a new globally unique S3 bucket name in the new region
   - Update the `bootstrap_bucket` variable with your new bucket name
   ```hcl
   variable "bootstrap_bucket" {
     description = "S3 bucket for Palo Alto bootstrap configuration"
     type        = string
     default     = "palo-bootstrap-494825111641"  # Change to your unique bucket name
   }
   ```
   
   - Ensure the bucket name is globally unique across all AWS accounts

3. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify Route Tables**
   - Check TGW route tables:
     ```bash
     aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id <spoke-rt-id> --filters "Name=type,Values=static" --region <region>
     aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id <security-rt-id> --filters "Name=type,Values=static" --region <region>
     ```
   
   - Check TGW attachment subnet route table:
     ```bash
     aws ec2 describe-route-tables --route-table-ids <tgw-attachment-rt-id> --region <region>
     ```

5. **Fix TGW Attachment Subnet Routes if Needed**
   - If routes point to TGW instead of GWLB endpoint:
     ```bash
     aws ec2 replace-route --route-table-id <tgw-attachment-rt-id> --destination-cidr-block <spoke-cidr> --vpc-endpoint-id <gwlbe-id> --region <region>
     ```

6. **Update Terraform Code**
   - Comment out the conflicting route resources in `main.tf` to avoid future conflicts:
     ```hcl
     # resource "aws_route" "security_tgw_to_gwlb_endpoint_route" {
     #   count                  = length(var.spoke_vpc_cidrs)
     #   route_table_id         = module.security_vpc.custom_route_table_ids["tgw"]
     #   destination_cidr_block = var.spoke_vpc_cidrs[count.index]
     #   vpc_endpoint_id        = module.gwlb.security_vpc_endpoint_ids[0]
     # }
     ```

## Testing the Deployment

1. **Verify East-West Traffic**
   - Launch EC2 instances in different spoke VPCs
   - Test connectivity between them (ping, SSH, etc.)
   - Traffic should flow through the firewall (check firewall logs)

2. **Verify Outbound Traffic**
   - Test internet connectivity from spoke VPC instances
   - Traffic should flow through the firewall (check firewall logs)

3. **Verify Inbound Traffic**
   - Test connectivity to applications from the internet
   - Traffic should flow through the firewall (check firewall logs)

## Troubleshooting

### Common Issues

1. **Traffic Bypassing Firewall**
   - Check TGW attachment subnet route table routes for spoke CIDRs
   - Ensure they point to GWLB endpoint, not TGW

2. **Asymmetric Routing**
   - Verify "appliance mode" is enabled on TGW attachment
   - Check route propagation settings

3. **Connectivity Issues**
   - Verify security groups allow necessary traffic
   - Check firewall rules and NAT configuration

## Architecture Diagram

```
                                                 ┌───────────────────┐
                                                 │                   │
                                                 │    Internet       │
                                                 │                   │
                                                 └─────────┬─────────┘
                                                           │
                                                           │
                                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                                     Security VPC (10.11.0.0/16)                           │
│                                                                                           │
│  ┌───────────────┐          ┌───────────────┐          ┌───────────────┐                  │
│  │ Public Subnet │          │  GWLB Subnet  │          │ TGW Attachment│                  │
│  │               │          │               │          │    Subnet     │                  │
│  │  ┌─────────┐  │          │  ┌─────────┐  │          │               │                  │
│  │  │ Firewall│  │          │  │  GWLB   │  │          │               │                  │
│  │  │VM-Series│◄─┼──────────┼──┤Endpoint │◄─┼──────────┼───┐           │                  │
│  │  └─────────┘  │          │  └─────────┘  │          │   │           │                  │
│  │       ▲       │          │               │          │   │           │                  │
│  └───────┼───────┘          └───────────────┘          │   │           │                  │
│          │                                             │   │           │                  │
│          │                                             │   │           │                  │
│          ▼                                             │   ▼           │                  │
│  ┌───────────────┐                                     │ ┌─────────┐   │                  │
│  │     NLB       │                                     │ │ Transit │   │                  │
│  └───────────────┘                                     │ │ Gateway │   │                  │
│                                                        │ └─────────┘   │                  │
└────────────────────────────────────────────────────────┼───────┬───────┼──────────────────┘
                                                         │       │       │
                                                         │       │       │
                                                         ▼       ▼       ▼
                                           ┌─────────────────────────────────────┐
                                           │         Transit Gateway             │
                                           │                                     │
                                           │  ┌─────────────┐  ┌─────────────┐   │
                                           │  │Spoke RT     │  │Security RT  │   │
                                           │  │             │  │             │   │
                                           │  └─────────────┘  └─────────────┘   │
                                           │                                     │
                                           └────────────┬────────────────┬───────┘
                                                        │                │
                                                        │                │
                                                        ▼                ▼
                                        ┌───────────────────────┐ ┌───────────────────────┐
                                        │  Spoke VPC A          │ │  Spoke VPC B          │
                                        │  (10.12.0.0/16)       │ │  (10.13.0.0/16)       │
                                        │                       │ │                       │
                                        │  ┌───────────────┐    │ │  ┌───────────────┐    │
                                        │  │ EC2 Instances │    │ │  │ EC2 Instances │    │
                                        │  └───────────────┘    │ │  └───────────────┘    │
                                        └───────────────────────┘ └───────────────────────┘
```

## Traffic Flow for East-West Traffic (Spoke A to Spoke B)

1. Traffic from Spoke A to Spoke B (10.13.0.0/16) is sent to the Transit Gateway
2. Transit Gateway looks up the route in the Spoke Route Table and forwards to Security VPC attachment
3. Traffic arrives in the TGW Attachment Subnet in Security VPC
4. TGW Attachment Subnet route table sends traffic to GWLB endpoint (key routing configuration)
5. GWLB endpoint forwards traffic to Palo Alto firewall for inspection
6. Firewall inspects traffic and sends it back to GWLB
7. GWLB sends traffic back to TGW Attachment Subnet
8. Traffic goes back to Transit Gateway
9. Transit Gateway looks up the route in the Security Route Table and forwards to Spoke B attachment
10. Traffic arrives at Spoke B
