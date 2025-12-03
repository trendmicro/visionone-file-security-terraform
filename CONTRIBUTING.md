# Contributing to Vision One File Security Terraform Module

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request, please open an issue on GitHub:

1. Check if the issue already exists in the [Issues](https://github.com/trendmicro/visionone-file-security-terraform/issues) section
2. If not, create a new issue with:
   - A clear, descriptive title
   - Detailed description of the problem or feature request
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior (for bugs)
   - Your environment details (Terraform version, Kubernetes version, cloud provider)

### Submitting Changes

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the coding standards below
3. **Test your changes** thoroughly
4. **Submit a Pull Request** with:
   - A clear description of what you changed and why
   - Reference to any related issues
   - Screenshots or logs if applicable

### Pull Request Process

1. Ensure your code follows the project's coding standards
2. Update documentation if you're changing functionality
3. Add or update examples if applicable
4. Your PR will be reviewed by maintainers
5. Once approved, your PR will be merged

## Coding Standards

### Terraform Best Practices

- Use consistent formatting (`terraform fmt`)
- Follow [Terraform naming conventions](https://www.terraform-best-practices.com/naming)
- Include meaningful variable descriptions
- Use `validation` blocks for input validation where appropriate
- Keep modules focused and single-purpose

### Code Style

- Use 2 spaces for indentation
- Use snake_case for resource names and variables
- Add comments for complex logic
- Keep lines under 120 characters when possible

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb (Add, Fix, Update, Remove, etc.)
- Reference issue numbers when applicable

Example:
```
Add support for custom node selectors in scanner deployment

- Add node_selector variable to v1fs module
- Update documentation with examples
- Fixes #123
```

## Development Setup

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured for your cluster
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0
- [terraform-docs](https://terraform-docs.io/user-guide/installation/) >= 0.16.0
- A Kubernetes cluster for testing

### Local Development

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/visionone-file-security-terraform.git
   cd visionone-file-security-terraform
   ```

2. Create a branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. Make your changes and test locally:
   ```bash
   cd examples/local
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   terraform init
   terraform validate
   terraform plan
   ```

4. Format your code:
   ```bash
   terraform fmt -recursive
   ```

5. Update documentation:
   ```bash
   make docs
   ```

## Documentation

We use [terraform-docs](https://terraform-docs.io/) to automatically generate input/output documentation from `variables.tf` and `outputs.tf` files.

### How It Works

README files contain special markers where terraform-docs injects generated content:

```markdown
<!-- BEGIN_TF_DOCS -->
(auto-generated content)
<!-- END_TF_DOCS -->
```

Content outside these markers is preserved and should be written manually (e.g., Architecture, Prerequisites, Quick Start, Troubleshooting).

### Updating Documentation

After modifying `variables.tf` or `outputs.tf`, run:

```bash
terraform-docs markdown table \
	--output-file ../../README.md \
	--output-mode inject \
	modules/v1fs

terraform-docs markdown table \
	--output-file README.md \
	--output-mode inject \
	examples/aws
```

### Adding New Examples

When creating a new example (e.g., `examples/azure/`):

1. Create your Terraform files (`main.tf`, `variables.tf`, `outputs.tf`, etc.)

2. Create a `README.md` with the terraform-docs markers:
   ```markdown
   # Azure Example for Vision One File Security

   (Your manual content: architecture, prerequisites, quick start, etc.)

   <!-- BEGIN_TF_DOCS -->
   <!-- END_TF_DOCS -->

   (More manual content: troubleshooting, resources, etc.)
   ```

3. Run the command:
   ```bash
   terraform-docs markdown table \
     --output-file README.md \
     --output-mode inject \
     examples/azure
   ```

## Testing

Before submitting a PR, please ensure:

1. `terraform validate` passes for all modules
2. `terraform fmt -check -recursive` shows no formatting issues
3. Your changes work with the example configurations
4. Documentation is updated if behavior changes

## Questions?

If you have questions about contributing, feel free to open an issue with the "question" label.

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project (Apache License 2.0).
