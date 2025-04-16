provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "simple-time-service-terraform-state"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
  name         = "simple-time-service-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # NAT Gateway for private subnets
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod" # Use single NAT Gateway for non-prod environments to save costs
  one_nat_gateway_per_az = var.environment == "prod" # Use one NAT Gateway per AZ for production

  # DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Add tags to all resources
  tags = {
    Environment = var.environment
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.alb.id]
    description     = "Allow inbound traffic from ALB only"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# IAM Roles
module "ecs_task_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.30"

  create_role             = true
  role_name               = "${var.app_name}-${var.environment}-task-execution-role"
  role_requires_mfa       = false
  trusted_role_services   = ["ecs-tasks.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

module "ecs_task_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.30"

  create_role           = true
  role_name             = "${var.app_name}-${var.environment}-task-role"
  role_requires_mfa     = false
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  # This module doesn't support direct policy document attachment with the parameters you were using
}

# Create a separate policy and attach it to the role
resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.app_name}-${var.environment}-task-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = module.ecs_task_role.iam_role_name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.app_name}-${var.environment}-logs"
    Environment = var.environment
  }
}

# ALB Module
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name               = "${var.app_name}-${var.environment}"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name             = "${var.app_name}-${var.environment}-tg"
      backend_protocol = "HTTP"
      backend_port     = var.app_port
      target_type      = "ip"
      health_check = {
        enabled             = true
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }
    }
  ]

  tags = {
    Environment = var.environment
  }
}

# ECS Cluster Module
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.2"

  cluster_name = "${var.app_name}-${var.environment}-cluster"

  cluster_settings = {
    "name"  = "containerInsights"
    "value" = var.enable_container_insights ? "enabled" : "disabled"
  }

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}

# ECS Service and Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  task_role_arn            = module.ecs_task_role.iam_role_arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.app_name}-${var.environment}-task-definition"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "app" {
  name                              = "${var.app_name}-${var.environment}-service"
  cluster                           = module.ecs.cluster_id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arns[0]
    container_name   = var.app_name
    container_port   = var.app_port
  }

  # Ignore task definition changes as it's updated via CI/CD
  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [module.alb]

  tags = {
    Name        = "${var.app_name}-${var.environment}-service"
    Environment = var.environment
  }
}
