variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "app_port" {
  description = "Port the container exposes"
  type        = number
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
}

variable "ecs_task_memory" {
  description = "Memory for the ECS task"
  type        = number
}

variable "desired_count" {
  description = "Desired count of container instances running"
  type        = number
}

variable "enable_container_insights" {
  description = "Enable container insights for the ECS cluster"
  type        = bool
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
}
