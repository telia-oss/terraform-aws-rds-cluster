terraform {
  required_version = ">= 0.14"
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

  name_prefix = var.name_prefix
  username    = "superuser"
  password    = "dolphins"
  port        = 5000
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}
