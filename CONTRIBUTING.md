# Contributing to AWS Palo Alto VM-Series Centralized Inspection Architecture

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to this Terraform template.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/palo-aws-centralized-inspection.git`
3. Create a new branch for your feature: `git checkout -b feature/your-feature-name`

## Development Guidelines

### Terraform Style

- Use consistent indentation (2 spaces)
- Use snake_case for resource names and variable names
- Include descriptive comments for complex resources
- Group related resources together
- Use modules for reusable components

### Documentation

- Update README.md with any new features or changes
- Document all variables in variables.tf with clear descriptions
- Update architecture diagrams if you change the architecture

### Testing

Before submitting a pull request, please ensure:

1. Your code passes `terraform validate`
2. Your code passes `terraform fmt`
3. You've tested the deployment in your own AWS environment

## Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the example files if you've added new variables
3. Submit a pull request with a clear description of the changes

## Code of Conduct

Please be respectful and constructive in all interactions related to this project.

## License

By contributing to this project, you agree that your contributions will be licensed under the project's MIT License.
