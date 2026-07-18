variable "aws_region" {
  description = "AWS region used by the Academy Sandbox."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for AWS resource names and tags."
  type        = string
  default     = "flask-cicd-aws"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "academy-sandbox"
}

variable "instance_type" {
  description = "EC2 instance type allowed by AWS Academy Sandbox."
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t2.nano",
      "t2.micro",
      "t2.small",
      "t2.medium",
      "t3.nano",
      "t3.micro",
      "t3.small",
      "t3.medium",
    ], var.instance_type)

    error_message = "The selected EC2 instance type is not allowed by this Sandbox."
  }
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to connect to EC2 over SSH."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid IPv4 or IPv6 CIDR."
  }
}

variable "key_name" {
  description = "Existing AWS Academy EC2 key pair."
  type        = string
  default     = "vockey"
}

variable "iam_instance_profile" {
  description = "Existing AWS Academy instance profile used by EC2."
  type        = string
  default     = "LabInstanceProfile"
}
