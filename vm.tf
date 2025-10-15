locals {
  vm_name = "vm-${var.environment}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "sample_vm_sg" {
  count  = var.enable_sample_vm ? 1 : 0
  name   = "SG used for sample VMs"
  vpc_id = var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id

  ingress {
    description = "SSH access to sample VMs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #module.vpc.private_subnets_cidr_blocks
  }

  egress {
    description      = "Allow all outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ssm_traffic" {
  name        = "${local.vpc_name}-ssm"
  description = "SSM traffic"
  vpc_id      = var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id

  tags = {
    Name = "ssm"
  }
}

resource "aws_security_group_rule" "ssm_traffic" {
  security_group_id = aws_security_group.ssm_traffic.id
  type              = "ingress"
  description       = "HTTPS traffic"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #module.vpc.private_subnets_cidr_blocks
  from_port         = 443
  to_port           = 443
}

resource "aws_network_interface" "sample_vm_eni" {
  count           = var.enable_sample_vm ? 1 : 0
  subnet_id       = var.sample_vm_subnet_id == "" ? module.vpc[0].private_subnets[0] : var.sample_vm_subnet_id
  security_groups = [aws_security_group.sample_vm_sg[0].id]

  tags = {
    Name = "sample_vm_network_interface"
  }
}

resource "aws_iam_role" "sample_vm_instance_role" {
  count              = var.enable_sample_vm ? 1 : 0
  name               = "sample-vm-instance-role"
  description        = "A role used to access CAST AI nodes via SSM"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": ["sts:AssumeRole","sts:TagSession"]
  }
}
EOF
  tags = {
    Name = local.vm_name
    "env" : var.environment
  }
}

resource "aws_iam_role_policy_attachment" "sample_vm_ssm_policy" {
  count      = var.enable_sample_vm ? 1 : 0
  role       = aws_iam_role.sample_vm_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "sample_vm_ec2_policy" {
  count      = var.enable_sample_vm ? 1 : 0
  role       = aws_iam_role.sample_vm_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceConnect"
}

resource "aws_iam_instance_profile" "sample_vm_instance_profile" {
  count = var.enable_sample_vm ? 1 : 0
  name  = "sample-vm-instance_profile"
  role  = aws_iam_role.sample_vm_instance_role[0].name
}

resource "aws_instance" "sample_vm" {
  count                = var.enable_sample_vm ? 1 : 0
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.sample_vm_instance_type
  iam_instance_profile = aws_iam_instance_profile.sample_vm_instance_profile[0].name

  network_interface {
    network_interface_id = aws_network_interface.sample_vm_eni[0].id
    device_index         = 0
  }

  tags = {
    Name = local.vm_name
    "env" : var.environment
  }

  depends_on = [
    module.vpc
  ]
}

resource "aws_vpc_endpoint" "endpoints" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])

  vpc_id             = var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id
  subnet_ids         = var.vpc_id == "" ? module.vpc[0].private_subnets : local.endpoint_subnet_ids
  security_group_ids = [aws_security_group.ssm_traffic.id]

  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  tags = {
    Name = local.vm_name
    "env" : var.environment
  }
}
