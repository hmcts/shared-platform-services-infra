locals {
  vnet_rg   = "rg-${var.product}-${var.env}"
  vnet_name = "${var.product}-networking-vnet-${var.env}"
}
