resource "ibm_is_instance" "main" {
  name           = var.name
  vpc            = var.vpc_id
  zone           = var.zone_name
  keys           = var.ibmcloud_ssh_key_id
  image          = var.image_name
  profile        = var.profile_name
  resource_group = var.resource_group_id

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = var.security_group_ids
  }
}


