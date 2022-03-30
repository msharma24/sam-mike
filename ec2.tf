module "vpc_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.4.0"

  name = "${var.environment}/vpc_instance"
  # instance_count = 1

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.xlarge"
  monitoring             = true
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = "koptest"
  user_data              = <<EOF
  #!/bin/bash
  echo "Hello"
  EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}
