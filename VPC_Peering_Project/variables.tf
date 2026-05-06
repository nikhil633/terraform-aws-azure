variable "primary_cidr_vpc" {
    description = "CIDR Range for primary_vpc"
    type = string
    default = "10.0.0.0/16"
}

variable "secondary_cidr_vpc" {
    description = "CIDR Range for primary_vpc"
    type = string
    default = "10.1.0.0/16"
}

variable "primary" {
    description = "value"
    type = string
    default = "us-east-1"
}

variable "secondary" {
  description = "value"
  type = string
  default = "us-west-1"
}

variable "primary_subnet" {
    description = "value"
    type = string
    default = "10.0.1.0/24"
}

variable "secondary_subnet" {
    description = "value"
    type = string
    default = "10.1.1.0/24"
}

variable "instance_type" {
  type = string
  default = "t2.nano"
}

variable "primary_key_name" {
  description = "Name of the SSH key pair for Primary VPC instance (us-east-1)"
  type        = string
  default     = ""
}

variable "secondary_key_name" {
  description = "Name of the SSH key pair for Secondary VPC instance (us-west-2)"
  type        = string
  default     = ""
}