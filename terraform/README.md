# SimpleTimeService AWS Infrastructure

This repository contains Terraform code to deploy the SimpleTimeService application on AWS using ECS Fargate in a secure and scalable manner.

## Architecture

The infrastructure includes:
- A VPC with 2 public and 2 private subnets across two availability zones
- NAT Gateways for private subnet internet access
- ECS Fargate cluster for running containers in private subnets
- Application Load Balancer in public subnets to handle traffic
- Security groups to restrict traffic flow
- IAM roles with least privilege permissions

## Prerequisites

Before deploying, you'll need:
- [Terraform](https://www.terraform.io/downloads.html) v1.2.0 or newer
- AWS CLI v2 installed and configured
- An AWS account with appropriate permissions

## AWS Authentication

**IMPORTANT**: Never commit AWS credentials to Git repositories!

Authenticate with AWS using one of these methods:

1. **Environment variables**:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   export AWS_REGION="us-west-2"
   ```

2. **AWS CLI profile**:
   ```bash
   # Configure your AWS CLI profile if not already set up
   aws configure 
   
   

3. **AWS IAM roles** (recommended for production):
   - If running in an AWS environment  use IAM roles
  

## Deployment Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/krishnamoorthyrajendran/particle41
   cd terraform
   ```

2. Update the `terraform.tfvars` file with your specific values:
   - Automatcally change the container_image 
  

3. Initialize Terraform to download the required modules:
   ```bash
   terraform init
   ```

4. Preview the changes:
   ```bash
   terraform plan
   ```

5. Apply the changes:
   ```bash
   terraform apply
   ```

## Cleanup

To destroy all resources created by Terraform:
```bash
terraform destroy
```
## Security Considerations

- All ECS tasks run in private subnets
- Traffic is restricted using security groups
- Containers run as non-root users (as specified in the Docker image)
- Least privilege IAM roles are used
