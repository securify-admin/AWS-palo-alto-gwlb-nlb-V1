data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for web servers
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Security group for web servers - allows all traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Web server instances
resource "aws_instance" "web_server" {
  count         = length(var.subnet_ids)
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index]
  key_name      = var.key_name
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = false
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    
    # Create main page
    echo "<html><body><h1>Web Server ${count.index + 1} in AZ ${element(var.availability_zones, count.index)}</h1><p>This is a test web server deployed behind a Palo Alto VM-Series firewall.</p></body></html>" > /var/www/html/index.html
    
    # Create health check page
    echo "<html><body><h2>OK</h2><p>Health check passed for Web Server ${count.index + 1}</p></body></html>" > /var/www/html/health
    
    # Add a header to indicate health check response
    echo '# Health check configuration' >> /etc/httpd/conf.d/health.conf
    echo '<Location "/health">' >> /etc/httpd/conf.d/health.conf
    echo '    Header always set Content-Type "text/html"' >> /etc/httpd/conf.d/health.conf
    echo '    Header always set X-Health-Status "OK"' >> /etc/httpd/conf.d/health.conf
    echo '</Location>' >> /etc/httpd/conf.d/health.conf
    
    # Install mod_headers for custom headers
    yum install -y mod_ssl mod_headers
    
    # Restart Apache to apply changes
    systemctl restart httpd
    EOF

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
