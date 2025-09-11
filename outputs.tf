# Generate Ansible inventory file with floating IP
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    floating_ip = ibm_is_floating_ip.ilab_fip.address
    ssh_key     = var.existing_ssh_key != "" ? var.existing_ssh_key : "${local.prefix}.pem"
  })
  filename = "${path.module}/inventory.ini"

  depends_on = [
    ibm_is_floating_ip.ilab_fip,
    null_resource.create_private_key
  ]
}

# Output the floating IP for reference
output "floating_ip" {
  description = "The floating IP address of the ilab instance"
  value       = ibm_is_floating_ip.ilab_fip.address
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.existing_ssh_key != "" ? "~/.ssh/${var.existing_ssh_key}" : "./${local.prefix}.pem"} ilab@${ibm_is_floating_ip.ilab_fip.address}"
}

output "ansible_command" {
  description = "Command to run the Ansible playbook"
  value       = "ansible-playbook -i inventory.ini playbook.yml"
}