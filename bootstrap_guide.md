# VM-Series Bootstrap Configuration Guide

This guide explains how to prepare the bootstrap configuration for Palo Alto VM-Series firewalls deployed in this architecture.

## Bootstrap Overview

Bootstrap is a process that allows Palo Alto Networks firewalls to automatically configure themselves when they first boot up. This is particularly useful in cloud environments where manual configuration would be time-consuming and error-prone.

## S3 Bucket Structure

The VM-Series firewall expects a specific directory structure in the S3 bucket:

```
s3://your-bootstrap-bucket/
├── config/
│   ├── init-cfg.txt
│   └── bootstrap.xml
├── content/
│   └── (content updates)
├── license/
│   └── (license files)
└── software/
    └── (PAN-OS software)
```

## Required Files

At minimum, you need to create:

1. **init-cfg.txt**: Basic initialization parameters
2. **bootstrap.xml**: Full configuration file

### Sample init-cfg.txt

```
type=dhcp-client
ip-address=
default-gateway=
netmask=
ipv6-address=
ipv6-default-gateway=
hostname=vm-series-firewall
vm-auth-key=
panorama-server=
panorama-server-2=
tplname=
dgname=
dns-primary=8.8.8.8
dns-secondary=8.8.4.4
op-command-modes=mgmt-interface-swap
dhcp-send-hostname=yes
dhcp-send-client-id=yes
dhcp-accept-server-hostname=yes
dhcp-accept-server-domain=yes
```

The `mgmt-interface-swap` option in the `op-command-modes` parameter is important for AWS deployments where eth0 is used for dataplane traffic rather than management.

### Creating bootstrap.xml

The bootstrap.xml file contains the full configuration for your firewall. You can create this file by:

1. Configuring a firewall manually with your desired settings
2. Exporting the configuration (Device > Setup > Operations > Export Named Configuration Snapshot)
3. Saving the exported XML file as bootstrap.xml

## IAM Permissions

The VM-Series firewall instances need permissions to access the S3 bucket. The Terraform code creates an IAM role with the necessary permissions, but you should verify that the role has:

- `s3:GetObject`
- `s3:ListBucket`

## Uploading Bootstrap Files

1. Create your bootstrap files locally
2. Create the required directory structure in your S3 bucket
3. Upload the files to the appropriate directories

```bash
# Example AWS CLI commands
aws s3 mb s3://your-bootstrap-bucket
aws s3api put-object --bucket your-bootstrap-bucket --key config/
aws s3api put-object --bucket your-bootstrap-bucket --key content/
aws s3api put-object --bucket your-bootstrap-bucket --key license/
aws s3api put-object --bucket your-bootstrap-bucket --key software/
aws s3 cp init-cfg.txt s3://your-bootstrap-bucket/config/
aws s3 cp bootstrap.xml s3://your-bootstrap-bucket/config/
```

## Verifying Bootstrap Success

After deploying the firewalls:

1. Wait for the instances to initialize (can take 5-10 minutes)
2. Connect to the management interface via HTTPS
3. If bootstrap was successful, you should be able to log in with your configured credentials
4. Check the dashboard for any warnings or errors

If bootstrap fails, you can check the instance's serial console output in the AWS EC2 console for troubleshooting information.

## Additional Resources

- [Palo Alto Networks VM-Series Bootstrap Documentation](https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-the-vm-series-firewall-in-aws)
- [Sample Configurations Repository](https://github.com/PaloAltoNetworks/aws-vm-series-bootstrap)
