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


# RDS
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "stage-sam-db"

  engine            = "mysql"
  engine_version    = "5.7.34"
  instance_class    = "db.t2.xlarge"
  allocated_storage = 800
  username          = "hybris"
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
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = [
    "subnet-000a409b4af5406d1",
    "subnet-0989a08f5741210b3",
    "subnet-0f5cc2d907038927b"
  ]

  # DB parameter group
  family = "mysql5.7"

  skip_final_snapshot = true

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false




}



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
  version = "~> 3.0"

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
  subnet_ids = [
    "subnet-000a409b4af5406d1",
    "subnet-0989a08f5741210b3",
    "subnet-0f5cc2d907038927b"
  ]

  # DB parameter group
  family = "mysql5.7"

  skip_final_snapshot = true

  # DB option group
  major_engine_version = "5.7"

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


