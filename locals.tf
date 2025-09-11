locals {
  prefix      = var.prefix != "" ? var.prefix : "${random_string.prefix.0.result}"
  ssh_key_ids = var.existing_ssh_key != "" ? [data.ibm_is_ssh_key.sshkey.id] : [ibm_is_ssh_key.generated_key[0].id]

  zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }


  tags = [
    "provider:ibm",
    "workspace:${terraform.workspace}",
  ]
}