# Variables that have default values and are not required to be set by the user. These can be overridden if needed, but will not cause an error if left unset.

variable "location" {
  type    = string
  default = "UK South"
}
