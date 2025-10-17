# AWS Analytics Platform - Deployment Guide

This guide will walk you through deploying the complete analytics platform infrastructure on AWS.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **Domain name** registered and hosted zone created in Route 53
5. **Git** for version control

## Quick Deployment Steps

### 1. Prepare Configuration

```bash
# Clone or create your project directory
mkdir aws-analytics-platform
cd aws-analytics-platform

# Copy the terraform.tfvars example
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# REQUIRED: Update these values
aws_region   = "us-west-2"
domain_name  = "yourdomain.com"  # Must exist in Route 53
project_name = "analytics-platform"
environment  = "prod"

# Optional: Customize instance sizes based on your needs
shiny_instance_type   = "t3.medium"    # or t3.large for more power
rstudio_instance_type = "t3.large"     # or t3.xlarge for heavy workloads

# Optional: Set scaling parameters
min_capacity     = 2
max_capacity     = 10
desired_capacity = 2
```

### 2. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure (takes 15-30 minutes)
terraform apply
```

### 3. Access Your Services

After deployment, your services will be available at:

- **Shiny Apps**: `https://shiny.yourdomain.com`
- **RStudio**: `https://rstudio.yourdomain.com`

Default RStudio credentials (CHANGE IMMEDIATELY):
- Username: `rstudio-user`
- Password: `ChangeMePlease123!`

## Infrastructure Components

### Core Services
- **VPC**: Multi-AZ network with public/private subnets
- **Load Balancers**: Application Load Balancers with SSL termination
- **Auto Scaling**: EC2 instances that scale based on demand
- **ECS Fargate**: Containerized Shiny applications
- **Storage**: S3 buckets and EFS shared file systems

### Security
- **WAF**: Web Application Firewall protection
- **GuardDuty**: Threat detection service
- **Security Groups**: Network access controls
- **KMS**: Encryption key management
- **VPC Flow Logs**: Network monitoring

### Data Services
- **Transfer Family**: SFTP server for data uploads
- **S3 Buckets**:
  - Data storage with lifecycle policies
  - Analytics results
  - Application logs
- **EFS**: Shared file system for R packages and data

### Monitoring
- **CloudWatch**: Dashboards and alarms
- **Route 53 Health Checks**: DNS-based monitoring
- **Application logs**: Centralized logging

## Configuration Options

### Adding SFTP Users

Edit your `terraform.tfvars` to include SFTP users:

```hcl
sftp_users = [
  {
    username   = "analyst1"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... (your public key)"
    home_dir   = "/data/analyst1"
  },
  {
    username   = "analyst2"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... (their public key)"
    home_dir   = "/data/analyst2"
  }
]
```

### Scaling Configuration

Adjust instance types and scaling parameters:

```hcl
# For development/testing
shiny_instance_type   = "t3.micro"
rstudio_instance_type = "t3.small"
min_capacity          = 1
max_capacity          = 3
desired_capacity      = 1

# For production with high load
shiny_instance_type   = "c5.large"
rstudio_instance_type = "m5.xlarge"
min_capacity          = 3
max_capacity          = 20
desired_capacity      = 5
```

## Data Access Patterns

### Uploading Data

1. **SFTP**: Use any SFTP client to connect to the Transfer Family endpoint
2. **S3 Direct**: Upload directly to S3 buckets using AWS CLI or console
3. **Web Interface**: Use the RStudio file upload interface

### Accessing Data from R

The infrastructure provides built-in functions in RStudio:

```r
# Read CSV from S3
df <- read_s3_csv("data/myfile.csv")

# Write results to S3
write_s3_csv(results, "results/analysis_output.csv")

# Access shared files via EFS
shared_data <- read.csv("/mnt/efs/shared-data/dataset.csv")
```

## Security Best Practices

### Immediate Security Tasks

1. **Change default passwords**:
   ```bash
   # SSH to an RStudio instance and run:
   sudo passwd rstudio-user
   ```

2. **Restrict SFTP access** by updating security group rules to allow only your IP ranges

3. **Configure user authentication** - integrate with your identity provider

4. **Review WAF rules** - customize based on your application needs

### Network Security

- All compute resources are in private subnets
- NAT Gateways provide secure internet access
- Security groups implement least-privilege access
- VPC Flow Logs monitor all network traffic

## Monitoring and Maintenance

### CloudWatch Dashboards

Access your monitoring dashboard:
1. Go to AWS CloudWatch console
2. Navigate to Dashboards
3. Open the `{project-name}-{environment}-infrastructure` dashboard

### Key Metrics to Monitor

- ALB response times and error rates
- ECS CPU and memory utilization
- S3 storage usage and costs
- EFS throughput and connections
- Auto Scaling Group instance health

### Cost Optimization

- Review S3 lifecycle policies (data moves to cheaper storage automatically)
- Monitor EFS usage and adjust throughput mode if needed
- Use Auto Scaling to minimize compute costs during low usage
- Consider Spot instances for development environments

## Troubleshooting

### Common Issues

1. **Certificate validation fails**:
   - Ensure your domain is properly configured in Route 53
   - Wait 5-10 minutes for DNS propagation

2. **Services not accessible**:
   - Check security group rules
   - Verify ALB health checks are passing
   - Review VPC routing tables

3. **SFTP connection fails**:
   - Verify public key format is correct
   - Check Transfer Family server status
   - Confirm security group allows port 22

### Useful Commands

```bash
# Check infrastructure status
terraform show

# View all outputs
terraform output

# Check specific service status
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
aws ecs list-services --cluster <cluster-name>
aws transfer describe-server --server-id <server-id>
```

### Getting Help

1. Check CloudWatch logs for application errors
2. Review AWS CloudFormation events for deployment issues
3. Use AWS Systems Manager Session Manager to access instances
4. Enable detailed monitoring for deeper insights

## Backup and Disaster Recovery

### Automated Backups

- **S3**: Versioning and cross-region replication available
- **EFS**: Automatic backups via AWS Backup service
- **RDS**: Point-in-time recovery (if added to the architecture)

### Recovery Procedures

- Infrastructure: Redeploy using Terraform
- Data: Restore from S3 versioning or EFS backups
- Applications: Container images stored in ECR

## Scaling and Future Enhancements

### Horizontal Scaling

The infrastructure supports scaling by:
- Increasing Auto Scaling Group capacity
- Adding more ECS Fargate tasks
- Deploying across additional availability zones

### Potential Enhancements

- **Database Integration**: Add RDS PostgreSQL for structured data
- **CI/CD Pipeline**: Implement automated deployments
- **Advanced Analytics**: Add EMR or SageMaker integration
- **API Gateway**: Expose analytics as REST APIs
- **Backup Automation**: Implement comprehensive backup strategy

## Cost Estimation

Approximate monthly costs (us-west-2, moderate usage):

- **Compute**: $200-500/month (based on instance sizes and Auto Scaling)
- **Storage**: $50-200/month (S3 + EFS)
- **Networking**: $50-100/month (ALB + NAT Gateways + data transfer)
- **Security**: $20-50/month (WAF + GuardDuty)
- **Total**: $320-850/month

Use the AWS Pricing Calculator for precise estimates based on your usage patterns.

## Support

For issues related to this infrastructure:
1. Check the troubleshooting section above
2. Review AWS service documentation
3. Open AWS support cases for service-specific issues
4. Monitor AWS Health Dashboard for service interruptions