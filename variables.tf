variable "region" {
  description = "The IBM Cloud region to deploy resources in."
  type        = string
  default     = "us-south"
}

variable "existing_resource_group" {
  description = "The name of an existing IBM Cloud resource group to deploy resources in."
  type        = string
}

variable "prefix" {
  description = "A prefix to prepend to all resource names."
  type        = string
  default     = "ilab"
}

variable "existing_ssh_key" {
  description = "The name of an existing SSH key in the selected region to use for VM access."
  type        = string
  default     = "rst-us-south"
}

variable "vpc_address_prefix" {
  description = "The address prefix management option for the VPC."
  type        = string
  default     = "auto"
}

variable "instance_profile" {
  description = "The instance profile to use for the VMs."
  type        = string
  default     = "bx2-4x16"
}

variable "image_name" {
  description = "The name of the image to use for the VMs."
  type        = string
  default     = "ibm-ubuntu-24-04-3-minimal-amd64-1"
}

variable "allowed_ssh_cidr" {
  description = "The CIDR block to allow SSH access from."
  type        = string
  default     = "0.0.0.0/0"
}

variable "allow_ip_spoofing" {
  description = "Enable IP spoofing on the instance network interface."
  type        = bool
  default     = true
}