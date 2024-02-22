locals {
  tags = {
    env = var.environment
  }
}

variable "environment" {
  description = "Name of the environment used to simulate a customer's VPC without access to the Internet"
  type        = string
}

variable "region" {
  type        = string
  description = "Region in which resource should be created"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IP address range"
  default     = "10.0.0.0/16"
}

variable "rest_api_service_name" {
  type        = string
  description = "DNS name that will be used for accessing the VPC endpoint service provided by CAST AI from different account."
}

variable "grpc_api_service_name" {
  type        = string
  description = "DNS name that will be used for accessing the VPC endpoint service provided by CAST AI from different account."
}

variable "vpc_id" {
  type        = string
  description = "VPC id to use; a new will be created if not provided"
  default     = ""
}

variable "enable_bastion" {
  type        = bool
  description = "Enable bastion to access private subnets"
  default     = false
}

variable "enable_sample_vm" {
  type        = bool
  description = "Enable sample VM"
  default     = false
}

variable "sample_vm_subnet_id" {
  type        = string
  description = "Subnet ID where sample VM will be placed"
  default     = ""
}
