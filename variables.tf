variable "ssh_port" {
    type        = number
    description = "SSH port"
    default     = 22
}

variable "ssh_user" {
  type = string
  default = "almalinux"
}