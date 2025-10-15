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
  description = "Service name used to access REST API"
}

variable "grpc_service_name" {
  type        = string
  description = "Service name used to access gRPC pod pinning API"
}

variable "api_grpc_service_name" {
  type        = string
  description = "Service name used to access API via gRPC"
}

variable "files_service_name" {
  type        = string
  description = "Service name used to download artifacts"
}

variable "kvisor_service_name" {
  type        = string
  description = "Service name used to access kvisor via gRPC"
}

variable "telemetry_service_name" {
  type        = string
  description = "Service name used to access telemetry via gRPC"
}

variable "private_dns_enabled" {
  type        = bool
  description = "Whether to enable private DNS records for all interface endpoints"
  default     = true
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

variable "sample_vm_instance_type" {
  type        = string
  description = "Instance type to use for the sample VM"
  default     = "t3.micro"
}
