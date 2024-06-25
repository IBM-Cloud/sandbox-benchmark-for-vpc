resource "ibm_is_security_group" "login_sg" {
  name           = "${var.basename}-bastion-sg"
  vpc            = ibm_is_vpc.sandbox-vpc.id
  resource_group = data.ibm_resource_group.resource_group.id
}

resource "ibm_is_security_group_rule" "login_ingress_tcp" {
  for_each  = toset(var.remote_allowed_ips)
  group     = ibm_is_security_group.login_sg.id
  direction = "inbound"
  remote    = each.key

  tcp {
    port_min = 22
    port_max = 22
  }
}

# tunneled connections from the login server to a cluster member
resource "ibm_is_security_group_rule" "login_egress_tcp" {
  group     = ibm_is_security_group.login_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

module "bastion_host" {
  source                = "./modules/instance"
  name                  = "${var.basename}-bastion-${local.uuid}"
  image_name            = data.ibm_is_image.linux.id
  vpc_id                = ibm_is_vpc.sandbox-vpc.id
  zone_name             = var.zones[0]
  ibmcloud_ssh_key_name = var.ibmcloud_ssh_key_name
  resource_group_id     = data.ibm_resource_group.resource_group.id
  security_group_ids    = [ibm_is_security_group.login_sg.id]
  subnet_id             = ibm_is_subnet.subnets[0].id
}

resource "ibm_is_floating_ip" "main" {
  name           = "${var.basename}-bastion-fip-${local.uuid}"
  target         = module.bastion_host.primary_network_interface_id
  resource_group = data.ibm_resource_group.resource_group.id

  lifecycle {
    ignore_changes = [resource_group]
  }
}
