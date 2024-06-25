##############################################################################
# Terraform Outputs
##############################################################################

output "vpc_name" {
  description = "The ID of the vpc"
  value       = ibm_is_vpc.sandbox-vpc.name
}
output "trusted_profile" {
  description = "The ID of the Trusted profile"
  sensitive   = true
  value       = ibm_iam_trusted_profile.profile_id.id
}

locals {
  linux_access        = "ssh -i [SSHKeyPath] -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 38080:%s:80 root@%s. You can access the sandbox from your local http://localhost:38080"
  floating_ip         = ibm_is_floating_ip.main.address
  dashboardVM_address = ibm_is_instance.dashboard-vm[0].primary_network_interface[0].primary_ip[0].address
}

output "access_info" {
  description = "Provides the commands needed to access the instances via the bastion tunnel"
  value = merge({
    tunnel = format(local.linux_access, local.dashboardVM_address, local.floating_ip)
  })
}
