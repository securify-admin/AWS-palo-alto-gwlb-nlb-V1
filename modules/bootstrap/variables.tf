variable "bucket_name" {
  description = "Name of the S3 bucket for bootstrap configuration"
  type        = string
}

variable "vm_auth_key" {
  description = "VM authentication key for Panorama"
  type        = string
  default     = ""
}

variable "panorama_server" {
  description = "IP address or FQDN of Panorama primary"
  type        = string
  default     = ""
}

variable "panorama_server_2" {
  description = "IP address or FQDN of Panorama secondary"
  type        = string
  default     = ""
}

variable "tplname" {
  description = "Panorama template stack name"
  type        = string
  default     = ""
}

variable "dgname" {
  description = "Panorama device group name"
  type        = string
  default     = ""
}

variable "op_command_modes" {
  description = "Operational command modes"
  type        = string
  default     = ""
}
