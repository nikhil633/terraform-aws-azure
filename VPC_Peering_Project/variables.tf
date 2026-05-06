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