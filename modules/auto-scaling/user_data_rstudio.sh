#!/bin/bash
yum update -y
yum install -y amazon-efs-utils

# Install R and dependencies
yum install -y R

# Mount EFS
mkdir -p /mnt/efs
echo "${efs_file_system_id}.efs.${region}.amazonaws.com:/ /mnt/efs efs defaults,_netdev" >> /etc/fstab
mount -a -t efs

# Install RStudio Server
wget https://download2.rstudio.org/server/centos7/x86_64/rstudio-server-rhel-2023.03.0-386-x86_64.rpm
yum install -y --nogpgcheck rstudio-server-rhel-2023.03.0-386-x86_64.rpm

# Configure RStudio Server
cat > /etc/rstudio/rserver.conf << 'EOF'
# Server Configuration File
www-port=8787
rsession-which-r=/usr/bin/R
auth-required-user-group=rstudio
server-health-check-enabled=1
EOF

# Create RStudio user group
groupadd rstudio

# Configure shared storage
mkdir -p /home/shared
ln -sf /mnt/efs/rstudio-home /home/shared/rstudio

# Set up sample user (in production, use proper user management)
useradd -m -g rstudio rstudio-user
echo "rstudio-user:ChangeMePlease123!" | chpasswd
mkdir -p /home/rstudio-user/R
chown -R rstudio-user:rstudio /home/rstudio-user

# Create R profile with S3 access
cat > /home/rstudio-user/.Rprofile << 'EOF'
# Load commonly used libraries
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Set up S3 bucket path
Sys.setenv(S3_BUCKET = "${s3_bucket_name}")

# Function to easily read from S3
read_s3_csv <- function(key) {
    bucket <- Sys.getenv("S3_BUCKET")
    aws.s3::s3read_using(FUN = read.csv,
                        object = key,
                        bucket = bucket)
}

# Function to write to S3
write_s3_csv <- function(x, key) {
    bucket <- Sys.getenv("S3_BUCKET")
    aws.s3::s3write_using(x, FUN = write.csv,
                         object = key,
                         bucket = bucket)
}

cat("Welcome to RStudio on AWS!\n")
cat("S3 bucket:", Sys.getenv("S3_BUCKET"), "\n")
cat("Use read_s3_csv() and write_s3_csv() for S3 operations\n")
EOF

chown rstudio-user:rstudio /home/rstudio-user/.Rprofile

# Install commonly used R packages
R -e "install.packages(c('aws.s3', 'DBI', 'RPostgres', 'dplyr', 'ggplot2', 'shiny', 'rmarkdown', 'devtools'), repos='https://cran.rstudio.com/')"

# Start RStudio Server
systemctl start rstudio-server
systemctl enable rstudio-server

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "Custom/RStudio",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/rstudio-server.log",
                        "log_group_name": "/aws/rstudio/server",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s