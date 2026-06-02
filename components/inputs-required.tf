variable "env" {
  type = string
}

variable "builtFrom" {
  type = string
}

variable "product" {
  type = string
}

variable "environment" {}
variable "oms_env" {}
variable "private_ip_address" {}
variable "project" {}
variable "subscription" {}
variable "vnet_name" {}
variable "vnet_rg" {}
variable "ssl_certificate" {}

# Declared to satisfy the shared tfvars file; not used in this component
variable "destinations" {}
variable "frontends" {}
