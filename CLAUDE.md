# CLAUDE.md - AI Assistant Guide for tech-lab-ilab

## Project Overview

**Project Name:** InstructLab Infrastructure on IBM Cloud
**Purpose:** Infrastructure as Code (IaC) project that provisions and configures InstructLab environments on IBM Cloud VPC
**Primary Technologies:** Terraform, Ansible, IBM Cloud VPC, InstructLab
**Target Platform:** Ubuntu 24.04 on IBM Cloud Virtual Servers

This repository automates the deployment of InstructLab (an AI model training and RAG platform) on IBM Cloud infrastructure using a declarative infrastructure-as-code approach.

---

## Repository Structure

```
tech-lab-ilab/
├── Infrastructure (Terraform)
│   ├── main.tf              # Core infrastructure resources (VPC, subnet, instance, etc.)
│   ├── variables.tf         # Input variable definitions
│   ├── data.tf             # Data source queries (zones, images, SSH keys)
│   ├── locals.tf           # Local computed values (prefix, tags, zones)
│   ├── outputs.tf          # Output values and inventory generation
│   ├── providers.tf        # IBM Cloud provider configuration
│   ├── versions.tf         # Terraform and provider version constraints
│   └── .terraform.lock.hcl # Dependency lock file
│
├── Configuration Management (Ansible)
│   ├── playbook.yml        # Main setup playbook (Python, InstructLab, models)
│   ├── rag-convert.yml     # Document conversion playbook for RAG
│   ├── inventory.tpl       # Template for Ansible inventory generation
│   └── inventory.ini       # Generated inventory (gitignored)
│
├── Cloud Init
│   └── cloud-init.yaml     # Initial VM bootstrap configuration
│
├── Documentation
│   ├── README.md           # User-facing documentation
│   ├── CRUSH.md            # Build/test commands and style guidelines
│   ├── CLAUDE.md           # This file - AI assistant guide
│   └── LICENSE             # Apache 2.0 license
│
└── Configuration
    └── .gitignore          # Git ignore patterns
```

---

## Technology Stack

### Infrastructure Layer
- **Terraform v1.82.1+**: Infrastructure provisioning
- **IBM Cloud VPC**: Cloud platform
- **terraform-ibm-modules**: Official IBM modules for resource group and security groups

### Configuration Layer
- **Ansible 2.9+**: Configuration management
- **cloud-init**: Initial VM bootstrap
- **mise**: Python version management (asdf successor)

### Application Layer
- **Python 3.11**: Runtime environment (via mise)
- **InstructLab**: AI model training and RAG platform
- **HuggingFaceTB/SmolVLM-Instruct**: Default model for data generation

### Compute Resources
- **Instance Profile**: bx2-4x16 (4 vCPUs, 16GB RAM)
- **OS**: Ubuntu 24.04 minimal
- **Storage**: Boot volume with auto-sizing

---

## Architecture Patterns

### Infrastructure Design
1. **VPC Isolation**: Each deployment creates isolated VPC with auto address prefixes
2. **Multi-AZ Support**: Public gateways and subnets across all availability zones
3. **SSH Key Management**: Auto-generates RSA 4096-bit keys if none provided
4. **Security Groups**: Minimal inbound (SSH only), full outbound access
5. **Floating IPs**: Public IP assignment for external access

### Configuration Management
1. **Idempotent Playbooks**: All Ansible tasks are safely re-runnable
2. **Virtual Environments**: Isolated Python environment in `~/ilab-venv`
3. **User Separation**: Dedicated `ilab` user with sudo privileges
4. **Directory Structure**: Organized data, models, and document directories

---

## File-by-File Guide

### Terraform Files

#### `main.tf` (main.tf:1-141)
**Purpose:** Core infrastructure resource definitions
**Key Resources:**
- `module.resource_group` (main.tf:2-6): IBM resource group lookup
- `random_string.prefix` (main.tf:9-15): Random prefix generation if not provided
- `tls_private_key.ssh` (main.tf:18-22): RSA 4096-bit SSH key generation
- `ibm_is_ssh_key.generated_key` (main.tf:25-31): SSH key registration in IBM Cloud
- `null_resource.create_private_key` (main.tf:34-42): Local private key file creation
- `ibm_is_vpc.lab` (main.tf:44-56): VPC with auto address prefix management
- `ibm_is_public_gateway.zones` (main.tf:58-65): Public gateways for all zones
- `ibm_is_subnet.zones` (main.tf:67-76): Subnets (64 IPs each) per zone
- `module.security_group` (main.tf:78-99): SSH inbound + all outbound rules
- `ibm_is_instance.lab` (main.tf:103-132): Ubuntu 24.04 compute instance
- `ibm_is_floating_ip.ilab_fip` (main.tf:135-141): Public IP address

**Important Patterns:**
- Conditional resource creation using `count` (main.tf:19, 25, 35)
- Ternary operators for SSH key selection (main.tf:110)
- Template file usage for cloud-init (main.tf:109-111)

#### `variables.tf` (variables.tf:1-52)
**Purpose:** Input variable definitions with defaults
**Required Variables:**
- `existing_resource_group`: IBM Cloud resource group name

**Optional Variables with Defaults:**
- `region`: "us-south"
- `prefix`: "ilab"
- `existing_ssh_key`: "rst-us-south"
- `instance_profile`: "bx2-4x16"
- `image_name`: "ibm-ubuntu-24-04-3-minimal-amd64-1"
- `allowed_ssh_cidr`: "0.0.0.0/0"
- `allow_ip_spoofing`: true

#### `data.tf` (data.tf:1-12)
**Purpose:** Data source queries for existing resources
**Data Sources:**
- `ibm_is_zones.regional`: Available zones in region
- `ibm_is_image.base`: Ubuntu 24.04 image lookup
- `ibm_is_ssh_key.sshkey`: Existing SSH key lookup

#### `locals.tf` (locals.tf:1-17)
**Purpose:** Computed local values
**Key Locals:**
- `prefix`: Uses provided prefix or random string
- `ssh_key_ids`: List of SSH key IDs (existing or generated)
- `vpc_zones`: Map of zone numbers to zone names
- `tags`: Standard tags (provider, workspace)

#### `outputs.tf` (outputs.tf:1-29)
**Purpose:** Output values and inventory file generation
**Outputs:**
- `floating_ip`: Instance public IP address
- `ssh_command`: Ready-to-use SSH connection command
- `ansible_command`: Ready-to-use Ansible playbook command

**Generated Files:**
- `inventory.ini`: Ansible inventory with floating IP and SSH key path

### Ansible Files

#### `playbook.yml` (playbook.yml:1-128)
**Purpose:** Main InstructLab setup playbook
**Target:** `ilab_servers` host group
**Privilege Escalation:** Uses `become: yes`

**Key Variables:**
- `ilab_user`: Ansible connection user (playbook.yml:6)
- `ilab_home`: User home directory (playbook.yml:7)
- `venv_path`: Virtual environment path (playbook.yml:8)
- `python_version`: "3.11" (playbook.yml:9)

**Task Sequence:**
1. System Updates (playbook.yml:12-21)
2. Base Package Installation (playbook.yml:23-34)
3. mise Installation (playbook.yml:36-42)
4. Python 3.11 Installation via mise (playbook.yml:44-54)
5. Directory Structure Creation (playbook.yml:56-67)
6. Virtual Environment Creation (playbook.yml:69-79)
7. pip Upgrade (playbook.yml:81-84)
8. InstructLab Installation with MPS support (playbook.yml:86-89)
9. InstructLab Configuration (playbook.yml:91-97)
10. SmolVLM Model Download (playbook.yml:119-127)

**Important Notes:**
- Granite embedding model download is commented out (playbook.yml:99-107)
- All Python operations use the virtual environment
- Creates directory structure: `ilab-data`, `models`, `documents`

#### `rag-convert.yml` (rag-convert.yml:1-31)
**Purpose:** Convert documents for RAG (Retrieval-Augmented Generation)
**Usage:** Run manually after adding documents to `~/documents`

**Task Sequence:**
1. Create `converted-documents` directory (rag-convert.yml:12-19)
2. Run `ilab rag convert` with taxonomy-base=empty (rag-convert.yml:21-31)

#### `inventory.tpl` (inventory.tpl:1-5)
**Purpose:** Template for Ansible inventory generation
**Generated By:** Terraform `local_file` resource in outputs.tf:2-13

**Variables:**
- `floating_ip`: Instance public IP address
- `ssh_key`: Path to SSH private key file

**Connection Settings:**
- `ansible_user`: ilab
- `ansible_ssh_common_args`: Disables strict host key checking

### Cloud Configuration

#### `cloud-init.yaml` (cloud-init.yaml:1-18)
**Purpose:** Initial VM bootstrap configuration
**Execution:** Runs on first boot before Ansible

**Tasks:**
1. Package update and upgrade (cloud-init.yaml:2-3)
2. Base package installation: python3-pip, build-essential, unzip, jq, git (cloud-init.yaml:4-10)
3. User creation: `ilab` user with sudo privileges (cloud-init.yaml:11-18)
4. SSH key authorization via template variable

### Configuration Files

#### `.gitignore` (gitignore:1-49)
**Purpose:** Exclude sensitive and generated files from version control

**Key Exclusions:**
- Terraform state files: `*.tfstate`, `.terraform/`
- Terraform variables: `*.tfvars`, `*.tfvars.json`
- Generated inventory: `inventory.ini`
- SSH keys: `*.pem` (implied)
- Python environments: `.venv/`, `venv/`, `.env`
- CRUSH directory: `.crush/`

---

## Development Workflows

### Initial Deployment Workflow

1. **Prerequisites Setup**
   ```bash
   # Ensure IBM Cloud credentials are configured
   # Set required environment variables
   export TF_VAR_existing_resource_group="your-resource-group"
   ```

2. **Infrastructure Provisioning**
   ```bash
   terraform init        # Initialize Terraform and download providers
   terraform plan        # Preview infrastructure changes
   terraform apply       # Create infrastructure (creates inventory.ini)
   ```

3. **Configuration Management**
   ```bash
   # Wait 2-3 minutes for cloud-init to complete
   ansible-playbook -i inventory.ini playbook.yml
   ```

4. **Access and Verification**
   ```bash
   # Use SSH command from terraform output
   ssh -i ./ilab.pem ilab@<floating-ip>
   source ~/ilab-venv/bin/activate
   ilab --version
   ```

### Document Processing Workflow

1. **Upload Documents**
   ```bash
   # From local machine
   scp -i ./ilab.pem document.pdf ilab@<floating-ip>:~/documents/
   ```

2. **Convert for RAG**
   ```bash
   # From local machine
   ansible-playbook -i inventory.ini rag-convert.yml

   # Or on server
   source ~/ilab-venv/bin/activate
   cd ~/documents
   ilab rag convert --taxonomy-base=empty --output-dir ~/converted-documents
   ```

### Infrastructure Update Workflow

1. **Modify Terraform Files**
   - Update `variables.tf` for new defaults
   - Modify `main.tf` for resource changes

2. **Plan and Apply**
   ```bash
   terraform fmt         # Format code
   terraform validate    # Validate configuration
   terraform plan        # Review changes
   terraform apply       # Apply changes
   ```

3. **Re-run Ansible if Needed**
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```

### Teardown Workflow

```bash
terraform destroy      # Destroys all infrastructure
# Manual cleanup: Remove generated files (*.pem, inventory.ini)
```

---

## Key Conventions and Patterns

### Naming Conventions

1. **Resource Names**: Use prefix + descriptive name
   - VPC: `${prefix}-vpc`
   - Instance: `${prefix}-lab`
   - Security Group: `${prefix}-frontend-sg`

2. **Variable Names**: Use snake_case
   - `existing_resource_group`
   - `allowed_ssh_cidr`

3. **Tag Structure**:
   - `provider:ibm`
   - `workspace:${terraform.workspace}`
   - `zone:${zone}` (for zonal resources)

### Code Style

#### Terraform (CRUSH.md:20-27)
- **Indentation**: 2 spaces
- **Naming**: snake_case for all identifiers
- **Documentation**: All variables must have descriptions
- **Grouping**: Logical resource grouping with comments
- **Version Pinning**: Always specify provider versions
- **Data Sources**: Prefer over hardcoded values

#### Ansible (CRUSH.md:29-35)
- **Indentation**: 2 spaces (YAML)
- **Task Names**: Descriptive, present tense
- **Become**: Use `become_user` for non-root operations
- **Virtual Environments**: Always use venv for Python packages
- **Idempotency**: All tasks must be safely re-runnable
- **Handlers**: Use for service management (not heavily used in this project)

### Security Patterns

1. **SSH Key Management**
   - Auto-generate 4096-bit RSA keys if not provided
   - Store private keys locally with 400 permissions
   - Never commit private keys to version control

2. **Security Groups**
   - Minimal inbound rules (SSH only)
   - CIDR-restricted SSH access (configurable)
   - Full outbound access for package installation

3. **User Management**
   - Dedicated `ilab` user with sudo
   - Password authentication disabled
   - SSH key-only authentication

4. **Secrets Management**
   - `.tfvars` files in .gitignore
   - No hardcoded credentials
   - Environment variable usage for sensitive data

---

## Common Tasks for AI Assistants

### When Asked to Add a New Resource

1. **Add to `main.tf`**: Define resource with appropriate naming
2. **Add variables**: If configurable, add to `variables.tf` with description
3. **Add outputs**: If user-facing, add to `outputs.tf`
4. **Update tags**: Add appropriate tags using `local.tags`
5. **Update README**: Document new resource in README.md

### When Asked to Modify Infrastructure

1. **Check dependencies**: Review resource dependencies before changes
2. **Validate syntax**: Run `terraform validate`
3. **Format code**: Run `terraform fmt`
4. **Update documentation**: Reflect changes in README.md and CLAUDE.md

### When Asked to Add Ansible Tasks

1. **Add to `playbook.yml`**: Insert in appropriate location
2. **Use become_user**: Switch to `ilab_user` for non-root tasks
3. **Check idempotency**: Ensure task can run multiple times safely
4. **Add task names**: Clear, descriptive names
5. **Test with check mode**: Suggest `ansible-playbook --check`

### When Asked About Configuration

1. **Check variables.tf**: Review variable definitions and defaults
2. **Check locals.tf**: Review computed values
3. **Check data.tf**: Review data source queries
4. **Reference line numbers**: Use format `file:line` (e.g., main.tf:44)

---

## Important Constraints and Limitations

### IBM Cloud Limitations
- **Region-Specific**: SSH keys and images are region-specific
- **Zone Availability**: Not all instance profiles available in all zones
- **Quota Limits**: IBM Cloud accounts have resource quotas

### Terraform State
- **Local State**: Project uses local state (not remote backend)
- **State Sensitivity**: State files contain sensitive data
- **Concurrent Runs**: No state locking for concurrent modifications

### Ansible Execution
- **SSH Dependency**: Requires working SSH connection
- **cloud-init Timing**: Must wait for cloud-init to complete (2-3 minutes)
- **Network Connectivity**: Requires internet access for package downloads

### InstructLab Constraints
- **Python 3.11 Required**: InstructLab requires Python 3.11
- **Memory Requirements**: Model operations require significant RAM
- **Model Downloads**: Large models require time and bandwidth

---

## Troubleshooting Guide

### Terraform Issues

**Issue**: `Error: No available zones`
```
Solution: Check region variable matches IBM Cloud region
File: variables.tf:1-5, data.tf:1-3
```

**Issue**: `Error: SSH key not found`
```
Solution: Verify existing_ssh_key exists in specified region
File: variables.tf:18-22, data.tf:9-11
```

**Issue**: `Error: Resource group not found`
```
Solution: Verify existing_resource_group name is correct
File: variables.tf:7-10, main.tf:2-6
```

### Ansible Issues

**Issue**: `Connection timeout`
```
Solution:
1. Verify floating IP is accessible
2. Check security group rules (main.tf:78-99)
3. Ensure cloud-init completed (wait 2-3 minutes)
4. Verify SSH key permissions: chmod 400 ./ilab.pem
```

**Issue**: `mise: command not found`
```
Solution: PATH not properly set, check mise installation
File: playbook.yml:36-42, 44-54
```

**Issue**: `InstructLab installation fails`
```
Solution:
1. Verify Python 3.11 is installed
2. Check virtual environment creation
3. Verify internet connectivity
File: playbook.yml:86-89
```

### Runtime Issues

**Issue**: `Model download slow or fails`
```
Solution:
1. Check internet connectivity on instance
2. Verify outbound security group rules
3. Use smaller models for testing (SmolVLM vs Granite)
File: playbook.yml:119-127
```

---

## AI Assistant Guidelines

### When Analyzing This Codebase

1. **Always reference line numbers**: Use format `file:line` (e.g., `main.tf:44`)
2. **Consider dependencies**: Terraform resources have implicit dependencies
3. **Check both layers**: Changes may require both Terraform and Ansible updates
4. **Review variables**: Always check `variables.tf` for configuration options
5. **Understand state**: Remember Terraform tracks state, changes may require updates

### When Making Changes

1. **Preserve patterns**: Follow existing naming and tagging conventions
2. **Maintain idempotency**: All Ansible tasks must be re-runnable
3. **Update documentation**: Modify README.md and CLAUDE.md for significant changes
4. **Format code**: Suggest `terraform fmt` after modifications
5. **Validate changes**: Recommend `terraform validate` and `terraform plan`

### When Answering Questions

1. **Be specific**: Reference exact files and line numbers
2. **Explain context**: Describe why code is structured a certain way
3. **Provide examples**: Show commands and expected outputs
4. **Consider security**: Highlight security implications of changes
5. **Reference docs**: Point to README.md and CRUSH.md for user guidance

### Security Awareness

1. **Never suggest committing**:
   - `*.tfvars` files
   - `*.pem` or private key files
   - State files
   - `inventory.ini`

2. **Always recommend**:
   - Restricting `allowed_ssh_cidr` in production
   - Using existing SSH keys when available
   - Proper file permissions (400 for private keys)
   - Environment variables for sensitive data

3. **Warn about**:
   - Opening security group rules beyond SSH
   - Disabling security features
   - Exposing sensitive data in outputs

### Testing Recommendations

1. **Terraform Changes**:
   ```bash
   terraform fmt
   terraform validate
   terraform plan  # Review before apply
   ```

2. **Ansible Changes**:
   ```bash
   ansible-playbook --syntax-check playbook.yml
   ansible-playbook --check -i inventory.ini playbook.yml
   ```

3. **End-to-End Testing**:
   - Deploy to test environment
   - Verify SSH connectivity
   - Run Ansible playbook
   - Validate InstructLab installation

---

## Quick Reference

### Critical Files Priority

**Must Understand First:**
1. `main.tf` - Core infrastructure
2. `variables.tf` - Configuration options
3. `playbook.yml` - Application setup

**Important Supporting Files:**
4. `data.tf` - Data sources
5. `locals.tf` - Computed values
6. `outputs.tf` - Outputs and inventory

**Reference Files:**
7. `README.md` - User documentation
8. `CRUSH.md` - Commands and style guide

### Environment Variables

```bash
# Required
export TF_VAR_existing_resource_group="your-resource-group"

# Optional
export TF_VAR_region="us-east"
export TF_VAR_prefix="myproject"
export TF_VAR_existing_ssh_key="my-key-name"
export TF_VAR_allowed_ssh_cidr="1.2.3.4/32"
```

### Common Commands

```bash
# Terraform
terraform init
terraform plan
terraform apply
terraform destroy
terraform fmt
terraform validate
terraform output floating_ip

# Ansible
ansible-playbook -i inventory.ini playbook.yml
ansible-playbook -i inventory.ini playbook.yml -v  # Verbose
ansible-playbook -i inventory.ini rag-convert.yml
ansible-playbook --check -i inventory.ini playbook.yml  # Dry run

# SSH
ssh -i ./ilab.pem ilab@<floating-ip>

# On Server
source ~/ilab-venv/bin/activate
ilab --version
ilab config init
ilab model download -rp <model-repo>
ilab rag convert --taxonomy-base=empty --output-dir ~/converted-documents
```

### File Ownership

| File/Directory | Owner | Purpose |
|---------------|-------|---------|
| `*.tf` | Infrastructure team | Terraform configuration |
| `*.yml` | Configuration team | Ansible playbooks |
| `cloud-init.yaml` | Both teams | VM bootstrap |
| `README.md` | Documentation | User guide |
| `CRUSH.md` | Development | Style guide |
| `CLAUDE.md` | AI/Documentation | AI assistant guide |

---

## Version Information

**Terraform**: 1.0+
**IBM Cloud Provider**: 1.82.1
**Ansible**: 2.9+
**Python**: 3.11 (via mise)
**InstructLab**: Latest (installed via pip)
**Target OS**: Ubuntu 24.04 minimal

---

## Additional Resources

- **IBM Cloud VPC Docs**: https://cloud.ibm.com/docs/vpc
- **Terraform IBM Provider**: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs
- **InstructLab Docs**: https://github.com/instructlab/instructlab
- **mise Documentation**: https://mise.jdx.dev/
- **Ansible Best Practices**: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html

---

## Document Maintenance

**Last Updated**: 2025-11-15
**Maintained By**: Repository contributors
**Update Frequency**: Update when significant infrastructure or workflow changes occur

**When to Update:**
- New Terraform resources added
- Ansible playbook structure changes
- New workflows introduced
- Security patterns modified
- Version requirements change
