output "primary_network_interface_id" {
  value = ibm_is_instance.main.primary_network_interface[0].id
}
