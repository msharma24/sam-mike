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

  enable_nat_gateway   = true
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


# RDS

module "mysql_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/mysql"
  version = "4.3.0"

  name        = "${var.environment}-mysql-sg"
  description = "Security group with MySQL/Aurora using port 3306"
  vpc_id      = module.vpc.vpc_id

  auto_ingress_with_self = []
  ingress_cidr_blocks    = [module.vpc.vpc_cidr_block]
}



module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.4.0"

  identifier = "sam-db"

  engine            = "mysql"
  engine_version    = "8.0.23"
  instance_class    = "db.r5.xlarge"
  allocated_storage = 200
  username          = "admin"
  password          = random_password.mysql_master_password.result

  snapshot_identifier = var.snapshot_identifier
  port                = "3306"


  vpc_security_group_ids = [
    module.mysql_security_group.security_group_id
  ]

  maintenance_window = "Sat:00:00-Sat:03:00"
  backup_window      = "03:00-06:00"


  tags = {
    Owner       = "user"
    DNS         = "stage-rds.databridge.internal"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = module.vpc.database_subnets

  # DB parameter group
  family = "mysql8.0"

  skip_final_snapshot = true

  # DB option group
  major_engine_version = "8.0"

  # Database Deletion Protection
  deletion_protection = false




}

################################################################################

resource "random_password" "mysql_master_password" {
  length           = 24
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  override_special = "$"
}


################################################################################

resource "aws_ssm_parameter" "ssm_parameter" {
  name        = "/SAM/MYSQL/MasterPassword"
  description = "MySQL cluster master password"
  type        = "SecureString"
  value       = random_password.mysql_master_password.result
}

################################################################################


################################################################################
# VPC Module Spoke VPC A - SSM Endpoint
################################################################################
module "vpc_ssm_endpoint" {

  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  vpc_id = module.vpc.vpc_id

  security_group_ids = [module.vpc.default_security_group_id]
  endpoints = {
    s3 = {
      service    = "s3"
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "spoke-vpc-a-s3-vpc-endpoint" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true,
      subnet_ids          = module.vpc.private_subnets
    },
    ec2messages = {
      service             = "ec2messages",
      private_dns_enabled = true,
      subnet_ids          = module.vpc.private_subnets
    }
  }
}
