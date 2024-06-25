# Get SSH Key for Virtual Server creates
data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ibmcloud_ssh_key_name
}

resource "ibm_is_instance" "main" {
  name           = var.name
  vpc            = var.vpc_id
  zone           = var.zone_name
  keys           = [data.ibm_is_ssh_key.ssh_key_id.id]
  image          = var.image_name
  profile        = var.profile_name
  resource_group = var.resource_group_id

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = var.security_group_ids
  }
}
