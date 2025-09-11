# CRUSH Configuration

## Build/Test Commands
```bash
# Terraform commands
terraform init                    # Initialize Terraform
terraform plan                    # Plan infrastructure changes
terraform apply                   # Apply infrastructure changes
terraform destroy                 # Destroy infrastructure
terraform validate                # Validate configuration
terraform fmt                     # Format Terraform files

# Ansible commands
ansible-playbook -i inventory playbook.yml    # Run playbook
ansible-playbook --check playbook.yml         # Dry run
ansible-galaxy install -r requirements.yml    # Install roles
```

## Code Style Guidelines

### Terraform
- Use snake_case for resource names and variables
- Include descriptions for all variables
- Use consistent indentation (2 spaces)
- Group resources logically with comments
- Always specify provider versions
- Use data sources instead of hardcoded values where possible

### Ansible
- Use YAML with 2-space indentation
- Use descriptive task names
- Group related tasks with block/rescue
- Use variables for reusable values
- Include handlers for service management
- Use venv for Python 3.11 requirements (InstructLab)

### General
- Keep sensitive data in .tfvars (never commit)
- Use meaningful commit messages
- Document infrastructure decisions in README
- Target: Ubuntu 24 servers on IBM Cloud VPC
- InstructLab model: ibm-granite/granite-embedding-english-r2