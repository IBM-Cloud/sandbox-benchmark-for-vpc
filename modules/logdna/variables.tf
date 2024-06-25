##############################################################################
# Account Variables
##############################################################################

variable "plan" {
  description = "Type of service plan. See https://cloud.ibm.com/catalog/services/logdna for current plan definitions."
  type        = string
  validation {
    condition     = contains(["lite", "7-day", "14-day", "30-day", "hipaa"], var.plan)
    error_message = "Must provide a valid logdna plan, valid options are lite, 7-day, 14-day, 30-day, hipaa"
  }
}

variable "default_receiver" {
  description = "Flag to select the instance to collect platform logs"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the resource instance"
  type        = string
}

variable "tags" {
  description = "Tags set for LogDNA instance"
  type        = list(string)
  default     = ["logging", "public"]
}

variable "resource_group_name" {
  description = "Name of resource group."
  type        = string
  default     = ""
}

variable "region" {
  description = "Region for the logdna"
  type        = string
}
