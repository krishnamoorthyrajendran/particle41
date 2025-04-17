region = "ap-south-1"
environment               = "dev"
vpc_cidr                  = "10.0.0.0/16"
availability_zones        = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs      = ["10.0.3.0/24", "10.0.4.0/24"]
app_name                  = "simpletimeservice"
app_port                  = 3000
<<<<<<< Updated upstream
container_image = "krishnamoorthy1/particle41:72936da"
=======
container_image = "krishnamoorthy1/particle41:72936da"
>>>>>>> Stashed changes
ecs_task_cpu              = 256
ecs_task_memory           = 512
desired_count             = 1
enable_container_insights = true
log_retention_days        = 1
