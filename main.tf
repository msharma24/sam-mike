################################################################################
# VPC Module
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"


  name = "${var.environment}-sam-mike-vpc"
  cidr = var.vpc_cidr

  azs              = ["${var.region}a", "${var.region}b"]
  private_subnets  = var.private_subnet_cidr_list
  public_subnets   = var.public_subnet_cidr_list
  database_subnets = var.database_subnet_cidr_list

  enable_ipv6             = false
  create_igw              = true
  map_public_ip_on_launch = false

  enable_nat_gateway   = false
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  vpc_tags = {
    Name = "vpc"
  }

  private_subnet_tags = {

    Name = "vpc-private-subnet"
  }
  public_subnet_tags = {

    Name = "vpc-workload-subnet"
  }
}

