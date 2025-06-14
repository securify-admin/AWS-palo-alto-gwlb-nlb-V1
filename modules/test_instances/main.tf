resource "aws_security_group" "windows_sg" {
  count       = length(var.vpc_ids)
  name        = "windows-server-sg-${count.index}"
  description = "Security group for Windows test servers"
  vpc_id      = var.vpc_ids[count.index]

  # Allow RDP from anywhere (for testing)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RDP access"
  }

  # Allow ICMP for ping tests
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMP/ping"
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "windows-server-sg-${count.index}"
  }
}

# Get the latest Windows Server 2022 AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Using dynamic public IPs instead of static EIPs for test servers

# Windows Server instances in each spoke VPC
resource "aws_instance" "windows_server" {
  count         = length(var.vpc_ids)
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index]
  
  vpc_security_group_ids = [aws_security_group.windows_sg[count.index].id]
  
  # Get encrypted password using key pair
  key_name = var.key_name
  
  # Enable public interface
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<EOF
<powershell>
# Rename the computer
Rename-Computer -NewName "TestServer-${count.index + 1}" -Force
# Install IIS for web testing if needed
Install-WindowsFeature -name Web-Server -IncludeManagementTools
# Create a simple test page
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<html><body><h1>Test Server ${count.index + 1}</h1><p>This is a test server in Spoke VPC ${count.index + 1}.</p></body></html>"
# Enable ICMP (ping)
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
# Restart to apply changes
Restart-Computer -Force
</powershell>
EOF

  tags = {
    Name = "windows-test-server-${count.index + 1}"
  }
}
