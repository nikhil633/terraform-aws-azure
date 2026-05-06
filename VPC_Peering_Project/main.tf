resource "aws_vpc" "primary_vpc" {
    provider = aws.primary
    cidr_block = var.primary_cidr_vpc
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "primary_vpc-${var.primary}"
        Environment = "prod"
        purpose = "vpc_peering"
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
        purpose = "vpc_peering"
    }
}

resource "aws_subnet" "primary_subnet" {
    provider = aws.primary
    vpc_id     = aws_vpc.primary_vpc.id
    cidr_block = var.primary_subnet
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.primary.names[0]


    tags = {
        Name = "primary_subnet"
        Environment = "prod"
    }
}

resource "aws_subnet" "secondary_subnet" {
    provider = aws.secondary
    vpc_id     = aws_vpc.secondary_vpc.id
    cidr_block = var.secondary_subnet
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.secondary.names[0]


    tags = {
        Name = "secondary_subnet"
        Environment = "prod"
    }
}

resource "aws_internet_gateway" "primary_igw" {
    provider = aws.primary
    vpc_id = aws_vpc.primary_vpc.id



    tags = {
        Name = "primary-IGW"
        Environment = "prod"
    }
}

resource "aws_internet_gateway" "secondary_igw" {
    provider = aws.secondary
    vpc_id = aws_vpc.secondary_vpc.id



    tags = {
        Name = "secondary-IGW"
        Environment = "prod"
    }
}

resource "aws_route_table" "primary_rt" {
    provider = aws.primary
    vpc_id = aws_vpc.primary_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.primary_igw.id
    }

    tags = {
        Name = "Primary-route-table"
        Environment = "demo"
    }
}

resource "aws_route_table" "secondary_rt" {
    provider = aws.secondary
    vpc_id = aws_vpc.secondary_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.secondary_igw.id
    }

    tags = {
        Name = "secondary-route-table"
        Environment = "demo"
    }
}

resource "aws_route_table_association" "primary_rta" {
  provider = aws.primary
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

resource "aws_route_table_association" "secondary_rta" {
  provider = aws.secondary
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  peer_region = var.secondary
  auto_accept = false
}

resource "aws_vpc_peering_connection_accepter" "secondary_acceptor" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "primary_to_secondary" {
    provider = aws.primary
    route_table_id            = aws_route_table.primary_rt.id
    destination_cidr_block    = var.secondary_cidr_vpc
    vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

    depends_on = [aws_vpc_peering_connection_accepter.secondary_acceptor]

}

resource "aws_route" "secondary_to_primary" {
    provider                  = aws.secondary
    route_table_id            = aws_route_table.secondary_rt.id
    destination_cidr_block    = var.primary_cidr_vpc
    vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

    depends_on = [aws_vpc_peering_connection_accepter.secondary_acceptor]
}

resource "aws_security_group" "primary_sg" {
  provider    = aws.primary
  name        = "primary-vpc-sg"
  description = "Security group for Primary VPC instance"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_cidr_vpc]
  }

  ingress {
    description = "All traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_cidr_vpc]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Primary-VPC-SG"
    Environment = "Demo"
  }
}

# Security Group for Secondary VPC EC2 instance
resource "aws_security_group" "secondary_sg" {
  provider    = aws.secondary
  name        = "secondary-vpc-sg"
  description = "Security group for Secondary VPC instance"
  vpc_id      = aws_vpc.secondary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_cidr_vpc]
  }

  ingress {
    description = "All traffic from Primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.primary_cidr_vpc]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Secondary-VPC-SG"
    Environment = "Demo"
  }
}

# EC2 Instance in Primary VPC
resource "aws_instance" "primary_instance" {
  provider               = aws.primary
  ami                    = data.aws_ami.primary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  key_name               = var.primary_key_name

  user_data = local.primary_user_data

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name        = "Primary-VPC-Instance"
    Environment = "Demo"
    Region      = var.primary
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_acceptor]
}

# EC2 Instance in Secondary VPC
resource "aws_instance" "secondary_instance" {
  provider               = aws.secondary
  ami                    = data.aws_ami.secondary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.secondary_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  key_name               = var.secondary_key_name

  user_data = local.secondary_user_data

  tags = {
    Name        = "Secondary-VPC-Instance"
    Environment = "Demo"
    Region      = var.secondary
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_acceptor]
}

# resource "aws_eip" "nat_eip" {
#   domain = "vpc"

#   tags = {
#     Name = "main-nat-eip"
#   }
# }

# resource "aws_nat_gateway" "main_nat" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public_subnet.id

#   depends_on = [aws_internet_gateway.main_igw]

#   tags = {
#     Name = "main-nat-gateway"
#   }
# }

# resource "aws_route" "private_nat_route" {
#   route_table_id         = aws_route_table.private_rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.main_nat.id
# }

# resource "aws_network_acl" "public_nacl" {
#   vpc_id = aws_vpc.main.id

#   subnet_ids = [aws_subnet.public_subnet.id]

#   ingress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = {
#     Name = "public-nacl"
#   }
# }

# resource "aws_network_acl" "private_nacl" {
#   vpc_id = aws_vpc.main.id

#   subnet_ids = [aws_subnet.private_subnet.id]

#   ingress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = {
#     Name = "private-nacl"
#   }
# }