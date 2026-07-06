output "apim_private_ip_address" {
  value = cidrhost(local.apim_subnet_cidr, 4)
}
