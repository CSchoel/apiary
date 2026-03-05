// The variables in this file are not needed by Terraform
// but the script for generating cloud-init templates for
// use with rpi-imager also reads from the Terraform
// credentials, so we create them here for convenience.

variable "AP_name" {
  type = string
}

variable "AP_password" {
  type      = string
  sensitive = true
}
