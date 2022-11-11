variable "rg" {
  default = "gaming"
}
variable "region" {
  default = "westeurope"
}

variable "vm_size" {
  default = "Standard_B1s"
}
variable "gpu_enabled" {
  default = false
}

# If you change this, check the directory names from gaming.yml (home directory of the user)
variable "user_name" {
  default = "gamer"
}

variable "priority" {
  default = ""
}
