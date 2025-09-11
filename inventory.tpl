[ilab_servers]
${floating_ip} ansible_user=ilab ansible_ssh_private_key_file=${ssh_key}

[ilab_servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'