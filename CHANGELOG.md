# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-14

### Added
- Initial release of the Palo Alto VM-Series Centralized Inspection Architecture template
- Modular design with separate modules for vpc, firewall, gwlb, nlb, tgw, and alb
- Support for deploying VM-Series firewalls with bootstrap configuration
- Gateway Load Balancer for east-west and outbound traffic inspection
- Network Load Balancer for inbound traffic inspection
- Transit Gateway for inter-VPC communication
- Comprehensive documentation including README, architecture diagram guide, and bootstrap guide
- Example configuration files and helper scripts

### Changed
- Converted project from a specific deployment to a reusable template
- Parameterized all environment-specific values
- Added detailed comments to improve code readability

### Fixed
- Corrected route table associations for proper traffic flow
- Fixed security group rules to allow necessary traffic
- Ensured proper IAM permissions for VM-Series bootstrap
