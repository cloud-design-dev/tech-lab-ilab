# Create resource group using IBM module
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.3.0"
  existing_resource_group_name = var.existing_resource_group
}

# Generate a random string if a project prefix was not provided
resource "random_string" "prefix" {
  count   = var.prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
  numeric = false
}

# Generate a new SSH key if one was not provided
resource "tls_private_key" "ssh" {
  count     = var.existing_ssh_key != "" ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Add a new SSH key to the region if one was created
resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh.0.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

# Write private key to file if it was generated
resource "null_resource" "create_private_key" {
  count = var.existing_ssh_key != "" ? 0 : 1
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh.0.private_key_pem}' > ./'${local.prefix}'.pem
      chmod 400 ./'${local.prefix}'.pem
    EOT
  }
}

resource "ibm_is_vpc" "lab" {
  name                        = "${var.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  address_prefix_management   = var.vpc_address_prefix
  default_network_acl_name    = "${var.prefix}-default-vpc-nacl"
  default_security_group_name = "${var.prefix}-default-vpc-sg"
  default_routing_table_name  = "${var.prefix}-default-vpc-rt"
  tags                        = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "ibm_is_public_gateway" "zones" {
    count = length(local.vpc_zones)
  name = "pgw-${local.vpc_zones[count.index].zone}"
  vpc  = ibm_is_vpc.lab.id
  zone = local.vpc_zones[count.index].zone
  resource_group = module.resource_group.resource_group_id
  tags = local.tags
}

resource "ibm_is_subnet" "zones" {
    count = length(local.vpc_zones)
  name            =  "subnet-${local.vpc_zones[count.index].zone}"
  vpc             = ibm_is_vpc.lab.id
  zone            = local.vpc_zones[count.index].zone
  total_ipv4_address_count  = 64
  resource_group = module.resource_group.resource_group_id
  public_gateway = ibm_is_public_gateway.zones[count.index].id
  tags = local.tags
}

module "security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.5.2"
  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = ibm_is_vpc.lab.id
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules         = [{
    name      = "allow-all-outbound"
    direction = "outbound"
    remote    = "0.0.0.0/0"
  },
  {
    name      = "allow-ssh-inbound"
    direction = "inbound"
    remote    = var.allowed_ssh_cidr
    tcp = {
      port_min = 22
      port_max = 22
    }
  }]
}



resource "ibm_is_instance" "lab" {
  name           = "${local.prefix}-lab"
  vpc            = ibm_is_vpc.lab.id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = module.resource_group.resource_group_id
  user_data      = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    ssh_public_key = var.existing_ssh_key != "" ? data.ibm_is_ssh_key.sshkey.public_key : tls_private_key.ssh[0].public_key_openssh
  }))

  metadata_service {
    enabled            = true
    protocol           = "https"
    response_hop_limit = 5
  }

  boot_volume {
    name = "${local.prefix}-bastion-volume"
  }

  primary_network_interface {
    subnet            = ibm_is_subnet.zones[0].id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.security_group.security_group_id]
  }

  zone      = local.vpc_zones[0].zone
  keys      = local.ssh_key_ids
  tags      = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}


resource "ibm_is_floating_ip" "ilab_fip" {
  name           = "${local.prefix}-${local.vpc_zones[0].zone}-fip"
#   zone           = local.vpc_zones[0].zone
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
  target       = ibm_is_instance.lab.primary_network_interface[0].id
}