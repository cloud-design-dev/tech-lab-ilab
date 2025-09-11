# InstructLab Infrastructure on IBM Cloud

This project provisions and configures an InstructLab environment on IBM Cloud VPC using Terraform and Ansible. It creates a complete setup for running InstructLab with Python 3.11 on Ubuntu 24.04.

## Architecture

- **Cloud Provider**: IBM Cloud VPC
- **Operating System**: Ubuntu 24.04 minimal
- **Instance Profile**: bx2-4x16 (4 vCPUs, 16GB RAM)
- **Python Version**: 3.11 (managed via mise)
- **InstructLab**: Latest version with MPS support
- **Model**: HuggingFaceTB/SmolVLM-Instruct (for quick data generation)

## Infrastructure Components

### Terraform Resources
- **VPC**: Isolated network environment with auto address prefix management
- **Public Gateway**: Internet access for all availability zones
- **Subnets**: One subnet per availability zone with 64 IPv4 addresses each
- **Security Group**: SSH access (port 22) and all outbound traffic
- **Compute Instance**: Single Ubuntu 24.04 server
- **Floating IP**: Public IP address for external access
- **SSH Key**: Auto-generated or use existing key

### Ansible Configuration
- **Python Environment**: Python 3.11 via mise with dedicated virtual environment
- **InstructLab Setup**: Complete installation with MPS support
- **Directory Structure**: Organized data, models, and documents directories
- **Model Download**: SmolVLM-Instruct model for efficient data generation

## Prerequisites

- IBM Cloud account with VPC access
- Terraform >= 1.0
- Ansible >= 2.9
- IBM Cloud CLI (optional, for manual operations)

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <repository-url>
   cd tech-lab-ilab
   ```

2. **Set required variables**:
   ```bash
   export TF_VAR_existing_resource_group="your-resource-group"
   # Optional: export TF_VAR_existing_ssh_key="your-ssh-key-name"
   ```

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure InstructLab**:
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```

5. **Connect to your instance**:
   ```bash
   # SSH command will be displayed in terraform output
   ssh -i ./ilab.pem ubuntu@<floating-ip>
   ```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `existing_resource_group` | IBM Cloud resource group name | - | Yes |
| `region` | IBM Cloud region | `us-south` | No |
| `prefix` | Resource name prefix | `ilab` | No |
| `existing_ssh_key` | Existing SSH key name | `rst-us-south` | No |
| `instance_profile` | VM instance profile | `bx2-4x16` | No |
| `image_name` | Ubuntu image name | `ibm-ubuntu-24-04-3-minimal-amd64-1` | No |
| `allowed_ssh_cidr` | SSH access CIDR block | `0.0.0.0/0` | No |

## Usage

### InstructLab Commands

After deployment, connect to your instance and activate the virtual environment:

```bash
# Activate the virtual environment
source ~/ilab-venv/bin/activate

# Check InstructLab version
ilab --version

# Initialize configuration (already done by Ansible)
ilab config init

# Download additional models
ilab model download -rp ibm-granite/granite-embedding-english-r2

# Start working with your data
cd ~/documents
# Add your documents here, then run:
ilab rag convert --taxonomy-base=empty --output-dir ~/converted-documents
```

### Document Processing

Use the included RAG conversion playbook for processing documents:

```bash
# After adding documents to ~/documents on the server
ansible-playbook -i inventory.ini rag-convert.yml
```

### Terraform Management

```bash
# View current state
terraform show

# Update infrastructure
terraform plan
terraform apply

# Destroy environment
terraform destroy
```

## Directory Structure

```
tech-lab-ilab/
├── main.tf              # Main infrastructure resources
├── variables.tf         # Input variables
├── data.tf             # Data sources
├── locals.tf           # Local values
├── outputs.tf          # Output values
├── providers.tf        # Provider configuration
├── versions.tf         # Version constraints
├── playbook.yml        # Main Ansible playbook
├── rag-convert.yml     # Document conversion playbook
├── inventory.tpl       # Ansible inventory template
└── README.md          # This file
```

## Server Directory Structure

After deployment, the server will have:

```
/home/ubuntu/
├── ilab-venv/          # Python virtual environment
├── ilab-data/          # InstructLab data directory
├── models/             # Downloaded models
├── documents/          # Your source documents
├── converted-documents/ # RAG-converted documents
└── .config/instructlab/ # InstructLab configuration
```

## Security Considerations

- SSH access is restricted to the CIDR block specified in `allowed_ssh_cidr`
- Private SSH keys are generated locally and not stored in state
- All outbound traffic is allowed for package installation and model downloads
- Consider restricting SSH access to specific IP ranges in production

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**: Check security group rules and floating IP assignment
2. **Ansible Fails**: Verify SSH key permissions (`chmod 400 ./ilab.pem`)
3. **Model Download Slow**: Large models may take time; consider using smaller models for testing
4. **Python Version Issues**: The playbook installs Python 3.11 via mise for compatibility

### Logs and Debugging

```bash
# Check Ansible verbose output
ansible-playbook -i inventory.ini playbook.yml -v

# SSH with debugging
ssh -i ./ilab.pem ubuntu@<floating-ip> -v

# Check InstructLab logs on server
tail -f ~/.config/instructlab/instructlab.log
```

## Contributing

1. Follow the code style guidelines in `CRUSH.md`
2. Test changes with `terraform validate` and `terraform fmt`
3. Update documentation for any new variables or resources
4. Use meaningful commit messages

## License

See LICENSE file for details.