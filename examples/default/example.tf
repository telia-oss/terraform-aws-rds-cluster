terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

module "rds" {
  source = "../../"

  name_prefix = "example"
  username    = "test"
  password    = "SomePassword123"
  port        = "5000"
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

output "security_group_id" {
  value = module.rds.security_group_id
}

output "endpoint" {
  value = module.rds.endpoint
}

output "port" {
  value = module.rds.port
}

