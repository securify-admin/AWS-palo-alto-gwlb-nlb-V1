# Architecture Diagram

This file serves as a placeholder for the architecture diagram. You should replace this with an actual diagram image file (architecture_diagram.png) when you publish this template to GitHub.

## Diagram Description

The architecture diagram should illustrate the following components and their relationships:

### Security VPC (10.11.0.0/16)
- **VM-Series Firewalls**: Two Palo Alto VM-Series firewalls deployed across two AZs
  - Each firewall has three interfaces: management, public, and private
  - Management interfaces in management subnets (10.11.0.0/24, 10.11.1.0/24)
  - Public interfaces in public dataplane subnets (10.11.4.0/24, 10.11.5.0/24)
  - Private interfaces in private dataplane subnets (10.11.2.0/24, 10.11.3.0/24)
- **Gateway Load Balancer (GWLB)**: Deployed in dedicated GWLB subnets (10.11.8.0/24, 10.11.9.0/24)
- **GWLB Endpoints**: Deployed in dedicated GWLBE subnets (10.11.10.0/24, 10.11.11.0/24)
- **Network Load Balancer (NLB)**: Deployed in public dataplane subnets for inbound traffic
- **Transit Gateway Attachments**: In TGW attachment subnets (10.11.6.0/24, 10.11.7.0/24)

### Transit Gateway
- Central hub connecting all VPCs
- Separate route tables for Security VPC and Spoke VPCs
- "Appliance mode" enabled on Security VPC attachment

### Spoke VPC A (10.12.0.0/16)
- App subnets with test instances (10.12.0.0/24, 10.12.1.0/24)
- Routes to other VPCs via Transit Gateway

### Spoke VPC B (10.13.0.0/16)
- App subnets with test instances (10.13.0.0/24, 10.13.1.0/24)
- Routes to other VPCs via Transit Gateway

### Web VPC (10.14.0.0/16)
- Private subnets with web servers (10.14.1.0/24, 10.14.2.0/24)
- Application Load Balancer (ALB) for distributing traffic to web servers

### Traffic Flow Patterns

#### East-West Traffic (VPC to VPC)
1. Traffic from Spoke VPC A to Spoke VPC B:
   - Leaves Spoke VPC A via Transit Gateway
   - Enters Security VPC via TGW attachment
   - Flows through GWLB endpoint to GWLB
   - Inspected by VM-Series firewall
   - Returns via GWLB to TGW attachment
   - Exits Security VPC via Transit Gateway
   - Arrives at Spoke VPC B

#### North-South Traffic (Outbound to Internet)
1. Traffic from Spoke VPC to Internet:
   - Leaves Spoke VPC via Transit Gateway
   - Enters Security VPC via TGW attachment
   - Flows through GWLB endpoint to GWLB
   - Inspected by VM-Series firewall
   - Exits via firewall's public interface to Internet Gateway

#### North-South Traffic (Inbound from Internet)
1. Traffic from Internet to Web VPC:
   - Arrives at Network Load Balancer in Security VPC
   - Forwarded to VM-Series firewall public interface
   - Inspected by VM-Series firewall
   - Exits via firewall's private interface
   - Flows through Transit Gateway to Web VPC
   - Arrives at web servers via Application Load Balancer

## Creating Your Diagram

You can create your architecture diagram using tools like:
- [draw.io](https://draw.io)
- [Lucidchart](https://www.lucidchart.com)
- [AWS Architecture Diagrams Tool](https://aws.amazon.com/architecture/icons/)

Save your diagram as architecture_diagram.png in the root directory of this repository.

## Example Diagram Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Internet                                   │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Security VPC                                  │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐              │
│  │   NLB   │───▶│ VM-Series│───▶│  GWLB   │◀───│ GWLB    │              │
│  │         │    │ Firewall │    │         │    │ Endpoints│              │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘              │
│                                      │                                  │
└──────────────────────────────────────┼──────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Transit Gateway                                 │
└───────────┬─────────────────────┬──────────────────────┬───────────────┘
            │                     │                      │
            ▼                     ▼                      ▼
┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│    Spoke VPC A    │  │    Spoke VPC B    │  │     Web VPC       │
│  ┌─────────────┐  │  │  ┌─────────────┐  │  │  ┌─────────────┐  │
│  │Test Instances│  │  │  │Test Instances│  │  │  │    ALB     │  │
│  └─────────────┘  │  │  └─────────────┘  │  │  └─────┬───────┘  │
│                   │  │                   │  │        │          │
│                   │  │                   │  │  ┌─────▼───────┐  │
│                   │  │                   │  │  │Web Servers  │  │
│                   │  │                   │  │  └─────────────┘  │
└───────────────────┘  └───────────────────┘  └───────────────────┘
```

