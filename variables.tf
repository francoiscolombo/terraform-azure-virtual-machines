#========================================================================================
#--- Parameters -------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
variable "resource_group" {
  description = "Resource group name"
}

variable "environment" {
  description = "Environment to create (will be present as a tag)"
}

variable "location" {
  description = "region where the resources should exist"
}

variable "ssh_key_private" {
  description = "path to ssh private key"
}

variable "ssh_public_key" {
  description = "Give path to public key for ssh access: "
}

variable "subnet_id" {
  description = "subnet id, get it from the subnet module"
}

variable "blob_connection_string" {
  description = "blob connection string, get it from the storage-account module"
}

variable "name_prefix" {
  description = "Set unique part of the name to give to resources: "
}

variable "admin_username" {
  description = "administrator user name"
}

variable "servers" {
  description = "list of public servers to create in the infrastructure"
  type = "list"
}

variable "image_publisher" {
  description = "name of the publisher of the image (az vm image list)"
}

variable "image_offer" {
  description = "the name of the offer (az vm image list)"
}

variable "image_sku" {
  description = "image sku to apply (az vm image list)"
}

variable "image_version" {
  description = "version of the image to apply (az vm image list)"
}

variable "ansible_playbook" {
  description = "path to ansible playbook used to provision this VM"
}

variable "ansible_platform" {
  description = "path to ansible platform description file"
}
