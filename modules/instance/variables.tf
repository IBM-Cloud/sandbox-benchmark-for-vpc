
variable "name" {
  description = "The name for bastion instance"
  type        = string
}

variable "image_name" {
  description = "The name of the image used to create the instance"
  type        = string
}

variable "profile_name" {
  description = "The machine profile name"
  type        = string
  default     = "cx2-4x8"
}

variable "vpc_id" {
  description = "The id of this instance's parent VPC"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet"
  type        = string
}

variable "zone_name" {
  description = "The zone to create the instance in"
  type        = string
}

variable "ibmcloud_ssh_key_name" {
  description = "The id of the ssh keys"
  type        = string
}

variable "resource_group_id" {
  description = "The resource group id"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group ids"
  type        = list(string)
}
