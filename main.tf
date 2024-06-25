#############################################################################
# © Copyright IBM Corp. 2023, 2023

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#############################################################################

##############################################################################
# Terraform Main IaC
##############################################################################

# Generate random identifier
resource "random_string" "resource_identifier" {
  length  = 5
  upper   = false
  numeric = false
  lower   = true
  special = false
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

# Create LogDNA
module "logdna" {
  count               = var.logdna_ingestion_key == "" && var.logdna_integration ? 1 : 0
  source              = "./modules/logdna"
  plan                = var.logdna_plan
  default_receiver    = var.logdna_enable_platform
  region              = var.region
  name                = "${var.basename}-${var.logdna_name}"
  resource_group_name = var.resource_group
}

locals {
  uuid          = random_string.resource_identifier.result
  ingestion_key = var.logdna_ingestion_key == "" && var.logdna_integration ? module.logdna[0].ingestion_key : var.logdna_ingestion_key
}

# Create VPC
resource "ibm_is_vpc" "sandbox-vpc" {
  name                        = "${var.basename}-vpc-${local.uuid}"
  resource_group              = data.ibm_resource_group.resource_group.id
  default_security_group_name = "${var.basename}-dashboard-sg"
  address_prefix_management   = length(var.address_prefix_cidrs) != 0 ? "manual" : "auto"
}

resource "ibm_is_vpc_address_prefix" "prefixes" {
  count = length(var.address_prefix_cidrs)
  name  = format("%s-prefix-%d", ibm_is_vpc.sandbox-vpc.name, count.index)
  zone  = var.zones[count.index]
  vpc   = ibm_is_vpc.sandbox-vpc.id
  cidr  = var.address_prefix_cidrs[count.index]
}

# Create one subnet per zone
resource "ibm_is_subnet" "subnets" {
  depends_on = [
    ibm_is_vpc_address_prefix.prefixes
  ]

  count                    = length(var.zones)
  name                     = "${var.basename}-subnet-${count.index + 1}-${local.uuid}"
  vpc                      = ibm_is_vpc.sandbox-vpc.id
  zone                     = var.zones[count.index]
  total_ipv4_address_count = length(var.address_prefix_cidrs) == 0 ? var.subnet_ipv4_count : null
  ipv4_cidr_block          = length(var.address_prefix_cidrs) != 0 ? var.subnet_cidrs[count.index] : null
  resource_group           = data.ibm_resource_group.resource_group.id
  public_gateway           = ibm_is_public_gateway.gateway[count.index].id
}

# Create one public gateway per zone
resource "ibm_is_public_gateway" "gateway" {
  count          = length(var.zones)
  name           = "${var.basename}-pgw-${count.index + 1}-${local.uuid}"
  vpc            = ibm_is_vpc.sandbox-vpc.id
  zone           = var.zones[count.index]
  resource_group = data.ibm_resource_group.resource_group.id
}

# Create security group rules
# This will allow users to access dashboard api from bastion host
resource "ibm_is_security_group_rule" "dashboard_api_rule" {
  group     = ibm_is_vpc.sandbox-vpc.default_security_group
  direction = "inbound"
  remote    = ibm_is_security_group.login_sg.id

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

# This will allow users to access dashboard ui from bastion host
resource "ibm_is_security_group_rule" "dashboard_ui_rule" {
  group     = ibm_is_vpc.sandbox-vpc.default_security_group
  direction = "inbound"
  remote    = ibm_is_security_group.login_sg.id

  tcp {
    port_min = 80
    port_max = 80
  }
}

# This will allow users to ssh to the dashboard vsi from bastion host.
resource "ibm_is_security_group_rule" "dashboard_ssh_self" {
  group     = ibm_is_vpc.sandbox-vpc.default_security_group
  direction = "inbound"
  remote    = ibm_is_security_group.login_sg.id

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "dashboard_outbound" {
  group     = ibm_is_vpc.sandbox-vpc.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Create Virtual Server Instances

# Get SSH Key for Virtual Server creates
data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ibmcloud_ssh_key_name
}

# Get Linux image for Virtual Server creates
data "ibm_is_image" "linux" {
  name = "ibm-redhat-8-8-minimal-amd64-3"
}

### Create Trusted Profile
resource "ibm_iam_trusted_profile" "profile_id" {
  name = "${var.basename}-trusted-profile-${local.uuid}"
}

resource "ibm_iam_trusted_profile_policy" "vpc_policy" {
  profile_id = ibm_iam_trusted_profile.profile_id.id
  roles      = ["Writer", "Viewer", "Reader", "Editor"]

  resources {
    service           = "is"
    resource_group_id = data.ibm_resource_group.resource_group.id
  }
}

resource "ibm_iam_trusted_profile_policy" "rg_policy" {
  profile_id = ibm_iam_trusted_profile.profile_id.id
  roles      = ["Writer", "Viewer", "Reader", "Editor"]

  resources {
    resource_type = "resource-group"
    resource      = data.ibm_resource_group.resource_group.id
  }
}

### Create Dashboard VM ####
resource "ibm_is_instance" "dashboard-vm" {
  count          = 1
  name           = "${var.basename}-dashboard-${local.uuid}"
  image          = data.ibm_is_image.linux.id
  resource_group = data.ibm_resource_group.resource_group.id
  profile        = var.dashboard-machine-type
  primary_network_interface {
    subnet          = ibm_is_subnet.subnets[count.index % length(var.zones)].id
    security_groups = [ibm_is_vpc.sandbox-vpc.default_security_group]
  }
  default_trusted_profile_target = ibm_iam_trusted_profile.profile_id.id
  metadata_service {
    enabled            = true
    response_hop_limit = 2
  }
  vpc  = ibm_is_vpc.sandbox-vpc.id
  zone = element(var.zones, count.index)

  keys = [data.ibm_is_ssh_key.ssh_key_id.id]
  user_data = templatefile("${path.module}/scripts/dashboard-userdata.sh", {
    "ingestion_key"         = local.ingestion_key
    "region"                = var.region
    "iam_trustedprofile"    = ibm_iam_trusted_profile.profile_id.id
    "sandbox_uipassword"    = var.sandbox_uipassword
    "personal_access_token" = var.personal_access_token
    "sandbox_ui_repo_url"   = var.sandbox_ui_repo_url
  })
}
