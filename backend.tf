terraform {
  cloud {
    organization = "your-organization-name"  # Replace with your Terraform Cloud organization name

    workspaces {
      name = "palo-aws-poc-v3-gwlb-alb"  # You can customize this workspace name
    }
  }
}
