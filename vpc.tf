locals {
  vpc_name = "${var.environment}-vpc"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"
  count   = var.vpc_id == "" ? 1 : 0

  name            = local.vpc_name
  cidr            = var.vpc_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 3)]

  private_subnet_tags = {
    "cast.ai/routable" = "true"
  }
}

data "aws_subnets" "all_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id]
  }
}
