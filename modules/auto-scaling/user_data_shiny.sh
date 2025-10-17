#!/bin/bash
yum update -y
yum install -y amazon-efs-utils docker

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install R and Shiny dependencies
yum install -y R

# Mount EFS
mkdir -p /mnt/efs
echo "${efs_file_system_id}.efs.${region}.amazonaws.com:/ /mnt/efs efs defaults,_netdev" >> /etc/fstab
mount -a -t efs

# Install and configure Shiny Server
wget https://download3.rstudio.org/centos7/x86_64/shiny-server-1.5.19.995-x86_64.rpm
yum install -y --nogpgcheck shiny-server-1.5.19.995-x86_64.rpm

# Configure Shiny Server to use EFS
mkdir -p /srv/shiny-server
ln -sf /mnt/efs/shiny-apps/* /srv/shiny-server/

# Create a simple Shiny app if none exists
if [ ! -d "/mnt/efs/shiny-apps/hello" ]; then
    mkdir -p /mnt/efs/shiny-apps/hello
    cat > /mnt/efs/shiny-apps/hello/app.R << 'EOF'
library(shiny)

ui <- fluidPage(
    titlePanel("Hello Shiny on AWS!"),
    sidebarLayout(
        sidebarPanel(
            sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30)
        ),
        mainPanel(
            plotOutput("distPlot")
        )
    )
)

server <- function(input, output) {
    output$distPlot <- renderPlot({
        x <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
}

shinyApp(ui = ui, server = server)
EOF
fi

# Start Shiny Server
systemctl start shiny-server
systemctl enable shiny-server

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "Custom/Shiny",
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
                        "file_path": "/var/log/shiny-server.log",
                        "log_group_name": "/aws/shiny/server",
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