terraform {
  cloud {
    organization = "SecurifyTechnologies"  # Your Terraform Cloud organization name

    workspaces {
      name = "palo-aws-poc-v3-gwlb-alb"  # You can customize this workspace name
    }
  }
}
