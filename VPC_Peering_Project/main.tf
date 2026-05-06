resource "aws_vpc" "primary_vpc" {
    provider = aws.primary
    cidr_block = var.primary_cidr_vpc
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "primary_vpc-${var.primary}"
        Environment = "prod"
        purpose = vpc_peering
    }
}

resource "aws_vpc" "secondary_vpc" {
    provider = aws.secondary
    cidr_block = var.secondary_cidr_vpc
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "primary_vpc-${var.secondary}"
        Environment = "prod"
        purpose = vpc_peering
    }
}

