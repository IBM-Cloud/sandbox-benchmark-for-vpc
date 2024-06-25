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

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
  sensitive   = true
}

variable "ibmcloud_ssh_key_name" {
  description = "The IBM Cloud platform SSH key name used to deploy sandbox instances"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,}$", var.ibmcloud_ssh_key_name))
    error_message = "Use lowercase alphanumeric characters and hyphens only (without spaces)."
  }
}

variable "resource_group" {
  description = "The IBM resource group name to be associated with this IBM Cloud VPC Sandbox deployment"
  type        = string
  default     = "Default"
  validation {
    condition     = length(var.resource_group) <= 40 && can(regex("^[a-zA-Z0-9-_ ]+$", var.resource_group))
    error_message = "Use alphanumeric characters along with hyphens and underscores only."
  }
}

variable "region" {
  description = "IBM Cloud region where all resources will be deployed. SPR VSIs are available in Dallas, London, Frankfurt etc. Please refer [this](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui#next-gen-profiles)"
  type        = string
  default     = "us-south"
}

variable "zones" {
  description = "IBM Cloud zone name within the selected region where the Sandbox infrastructure should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli)"
  type        = list(string)
  default     = ["us-south-1"]
}

variable "address_prefix_cidrs" {
  type        = list(string)
  description = "Address prefixes to create in the VPC"
  default     = []
}

variable "subnet_cidrs" {
  type        = list(string)
  description = "Subnet cidrs to use in each zone, required when using `address_prefix_cidrs`"
  default     = []
}

variable "subnet_ipv4_count" {
  type        = number
  description = "Count of ipv4 address in each zone, ignored when using `address_prefix_cidrs`"
  default     = 256
  validation {
    condition     = can(regex("^8$|^16$|^32$|^64$|^128$|^256$|^512$|^1024$|^2048$|^4096$|^8192$|^16384$", var.subnet_ipv4_count))
    error_message = "Please enter the valid IPV4 address count for the subnet."
  }
}

variable "basename" {
  description = "Basename of the created resource"
  type        = string
  default     = "sbox"
}

variable "dashboard-machine-type" {
  type        = string
  description = "Application 1 VM machine types"
  default     = "bx2d-4x16"
}

variable "remote_allowed_ips" {
  description = "List of ips to allow access to this bastion host"
  type        = list(string)

  # Validation to ensure all IPs in allowed_ips are valid IPv4 addresses
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|0)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|0)$", join(",", var.remote_allowed_ips))) && !contains(var.remote_allowed_ips, "0.0.0.0")
    error_message = "remote_allowed_ips should not be empty or 0.0.0.0 and all IPs must be valid IPv4 addresses"
  }
}

########## LogDNA Parameters #############

variable "logdna_name" {
  description = "Name for LogDNA Instance."
  type        = string
  default     = "logging"
}

variable "logdna_integration" {
  description = "Set to false if LogDNA not needed, only recommend disabling for non-production environments."
  type        = bool
  default     = true
}

variable "logdna_ingestion_key" {
  description = "Provide existing LogDNA instance ingestion key. To get ingestion key, please follow this `https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-ingestion_key&interface=ui`. If not set, a new instance of LogDNA will be created when `logdna_integration` is true."
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition = can(try(
      regex("^$", var.logdna_ingestion_key),
      regex("^[[:alnum:]]{32}$", var.logdna_ingestion_key)
    ))
    error_message = "If provided, ingestion key should be 32 lower alphanumeric characters in length."
  }
}

variable "logdna_plan" {
  description = "Service plan used for new LogDNA instance, valid options are lite, 7-day, 14-day, 30-day, hipaa"
  type        = string
  default     = "lite"
  validation {
    condition     = contains(["lite", "7-day", "14-day", "30-day", "hipaa"], var.logdna_plan)
    error_message = "Must provide a valid logdna plan, valid options are lite, 7-day, 14-day, 30-day, hipaa"
  }
}

variable "logdna_enable_platform" {
  description = "Enables logging"
  type        = bool
  default     = false
}

variable "sandbox_uipassword" {
  description = "Sandbox UI password. Password must contain at least one uppercase character, one lowercase character, one number, and cannot contain the word 'password'. Password must be 12 to 63 characters long."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sandbox_uipassword) > 11 && length(var.sandbox_uipassword) < 64
    error_message = "Password must be 12 to 63 characters long."
  }

  validation {
    condition     = can(regex("[A-Z]", var.sandbox_uipassword))
    error_message = "Password must contain at least one uppercase character."
  }

  validation {
    condition     = can(regex("[a-z]", var.sandbox_uipassword))
    error_message = "Password must contain at least one lowercase character."
  }

  validation {
    condition     = can(regex("[0-9]", var.sandbox_uipassword))
    error_message = "Password must contain at least one number."
  }

  validation {
    condition     = !can(regex(".*password.*", var.sandbox_uipassword))
    error_message = "Password cannot contain the word 'password'."
  }
}

variable "personal_access_token" {
  description = "Personal access token, Internal IBM use only"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sandbox_ui_repo_url" {
  description = "Sandbox UI repo download URL, Sample repo URL https://github.com/username/repository-name/archive/master.zip"
  type        = string
  default     = "https://github.com/IBM-Cloud/sandbox-benchmark-dashboard-for-vpc/archive/main.zip"
}
