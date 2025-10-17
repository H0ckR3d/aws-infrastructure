# AWS Analytics Platform Infrastructure

This Terraform project creates a comprehensive, production-ready analytics platform on AWS based on the provided architecture diagram. The infrastructure includes R/Shiny applications, RStudio servers, data storage, and supporting services.

## Architecture Overview

The infrastructure includes:

- **Multi-AZ VPC** with public and private subnets
- **Application Load Balancers** for Shiny and RStudio applications
- **Auto Scaling Groups** for EC2 instances
- **ECS Fargate** for containerized Shiny applications
- **EFS** for shared file storage
- **S3 buckets** for data, results, and logs
- **AWS Transfer Family** for SFTP access
- **Security services**: WAF, GuardDuty, Shield (optional)
- **Monitoring**: CloudWatch dashboards and alarms
- **DNS**: Route 53 with SSL certificates

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Domain name** registered and managed in Route 53
4. **S3 bucket** for Terraform state (recommended for production)

## Quick Start

1. **Clone and configure:**
   ```bash
   # Copy the example variables file
   cp terraform.tfvars.example terraform.tfvars

   # Edit terraform.tfvars with your specific values
   # At minimum, update:
   # - aws_region
   # - domain_name
   # - project_name
   # - environment
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Deploy the infrastructure:**
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# Domain Configuration (REQUIRED)
domain_name = "yourdomain.com"  # Must be managed in Route 53

# Basic Configuration
aws_region   = "us-west-2"
project_name = "analytics-platform"
environment  = "prod"
owner        = "your-team"

# Network Configuration
vpc_cidr               = "10.0.0.0/16"
availability_zones     = ["us-west-2a", "us-west-2b"]
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.10.0/24", "10.0.20.0/24"]
```

### Optional SFTP Users

To configure SFTP users for data upload:

```hcl
sftp_users = [
  {
    username   = "analyst1"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
    home_dir   = "/data/analyst1"
  }
]
```

## Module Structure

```
├── main.tf                 # Main configuration
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Terraform and provider versions
├── providers.tf          # AWS provider configuration
└── modules/
    ├── networking/       # VPC, subnets, routing
    ├── security/         # Security groups, WAF, GuardDuty
    ├── load-balancers/   # ALB configuration
    ├── storage/          # S3, EFS, KMS keys
    ├── ecs/              # ECS cluster and services
    ├── auto-scaling/     # EC2 Auto Scaling Groups
    ├── transfer/         # AWS Transfer Family
    ├── certificates/     # SSL certificates
    ├── dns/              # Route 53 records
    └── monitoring/       # CloudWatch dashboards
```

## Security Features

- **Encryption at rest** for all storage services (S3, EFS)
- **Encryption in transit** with SSL/TLS certificates
- **VPC Flow Logs** for network monitoring
- **AWS WAF** for web application protection
- **GuardDuty** for threat detection
- **Security groups** with least privilege access
- **Private subnets** for application and data tiers

## Monitoring and Logging

- **CloudWatch dashboards** for infrastructure metrics
- **ALB access logs** stored in S3
- **VPC Flow Logs** for network analysis
- **ECS task logs** in CloudWatch
- **Custom alarms** for key metrics

## Data Flow

1. **Data Ingestion**:
   - SFTP uploads via AWS Transfer Family
   - Direct S3 uploads

2. **Processing**:
   - R/Shiny applications on EC2 instances
   - RStudio for interactive analysis
   - ECS Fargate for containerized workloads

3. **Storage**:
   - Raw data in S3 with lifecycle policies
   - Shared filesystems via EFS
   - Results stored in dedicated S3 bucket

## Accessing Services

After deployment, services will be available at:

- **Shiny Applications**: `https://shiny.yourdomain.com`
- **RStudio**: `https://rstudio.yourdomain.com`
- **SFTP**: Connect to the Transfer Family endpoint (see outputs)

## Cost Optimization

The infrastructure includes several cost optimization features:

- **S3 Lifecycle policies** for automatic data archiving
- **EFS Intelligent Tiering** for file storage optimization
- **Auto Scaling** to match compute capacity with demand
- **Spot instances** option for non-critical workloads (configure in variables)

## Maintenance

### Updating Infrastructure

```bash
# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Backup and Disaster Recovery

- **S3 versioning** enabled for data protection
- **Cross-region replication** can be configured
- **EFS backups** available through AWS Backup service
- **Multi-AZ deployment** for high availability

## Troubleshooting

### Common Issues

1. **Domain not in Route 53**: Ensure your domain is managed by Route 53
2. **Certificate validation**: DNS validation may take several minutes
3. **Resource limits**: Check AWS service quotas for your region
4. **Permissions**: Ensure your AWS credentials have sufficient permissions

### Useful Commands

```bash
# Check infrastructure status
terraform show

# View outputs
terraform output

# Destroy infrastructure (be careful!)
terraform destroy
```

## Support and Contributing

For issues and questions:
1. Check AWS CloudFormation events for deployment errors
2. Review CloudWatch logs for application issues
3. Consult AWS documentation for service-specific guidance

## License

This infrastructure code is provided under the MIT License.