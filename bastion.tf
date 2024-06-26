locals {
  bastion_name = "bastion-${var.environment}"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bastion_key_use_for_cloudwatch_logs" {
  count = var.enable_bastion ? 1 : 0

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow key usage for bastion logs"
    effect = "Allow"
    principals {
      identifiers = ["logs.${var.region}.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "kms:EncryptionContext:aws:logs:arn"
    }
  }

  statement {
    sid    = "Allow service-linked role use of the customer managed key"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
      type        = "AWS"
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
      type        = "AWS"
    }
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "kms:GrantIsForAWSResource"
    }
  }
}

resource "aws_kms_key" "bastion_key" {
  count       = var.enable_bastion ? 1 : 0
  description = "bastion key"
  policy      = data.aws_iam_policy_document.bastion_key_use_for_cloudwatch_logs[0].json
}

module "bastion_host" {
  source  = "Hapag-Lloyd/bastion-host-ssm/aws"
  version = "2.5.0"
  count   = var.enable_bastion ? 1 : 0

  vpc_id     = var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id
  subnet_ids = var.vpc_id == "" ? module.vpc[0].private_subnets : data.aws_subnets.all_vpc_subnets.ids

  iam_role_path = "/${local.bastion_name}/"
  iam_user_arns = [module.bastion_user[0].iam_user_arn]

  kms_key_arn = aws_kms_key.bastion_key[0].arn

  bastion_access_tag_value = "developers"

  resource_names = {
    prefix    = local.bastion_name
    separator = "-"
  }

  egress_open_tcp_ports = [22]

  schedule = {
    start = "0 0 * * MON-FRI"
    stop  = "0 22 * * MON-FRI"

    time_zone = "UTC"
  }

  ami_name_filter = "amzn2-ami-hvm-*-x86_64-ebs"

  tags = { "env" : var.environment }
}

module "bastion_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.32.1"
  count   = var.enable_bastion ? 1 : 0

  name = "${local.bastion_name}-user"

  password_reset_required       = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}
