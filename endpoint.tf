resource "aws_security_group" "cast_ai_vpc_service" {
  name   = "SG used by NGINX proxy VMs"
  vpc_id = module.vpc.vpc_id

  ingress {
    description      = "Accessing CAST AI endpoints"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_endpoint" "cast_ai_rest_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = var.rest_api_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.cast_ai_vpc_service.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "cast_ai_grpc_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = var.grpc_api_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.cast_ai_vpc_service.id]
  private_dns_enabled = true
}
