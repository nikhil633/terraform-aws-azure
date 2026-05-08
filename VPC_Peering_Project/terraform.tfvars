# Example terraform.tfvars file
# Copy this file to terraform.tfvars and update with your values

primary  = "us-east-1"
secondary = "us-west-1"

primary_cidr_vpc   = "10.0.0.0/16"
secondary_cidr_vpc = "10.1.0.0/16"

primary_subnet   = "10.0.1.0/24"
secondary_subnet = "10.1.1.0/24"

instance_type = "t2.nano"

# IMPORTANT: Create an EC2 key pair in both regions before running this demo
# Use different key names for clarity
primary_key_name   = "vpc-peering-demo-east-1"
secondary_key_name = "vpc-peering-demo-west-1"