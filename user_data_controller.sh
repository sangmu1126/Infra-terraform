#!/bin/bash
# user_data_controller.sh - Auto-provisioning for FaaS Controller

# 1. Update & Install Dependencies
yum update -y
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y git nodejs

# 2. Setup Application Directory
mkdir -p /home/ec2-user/faas-controller
chown ec2-user:ec2-user /home/ec2-user/faas-controller

# 3. Clone Code (As ec2-user)
# Note: Repo must be public OR use a token/key. Assuming public for demo or handling key separately.
# For private repos, we usually inject a Deploy Key via Secrets Manager or UserData parameter.
# Using the repo URL from previous context: https://github.com/sangmu1126/Infra-controller.git
su - ec2-user -c "git clone https://github.com/sangmu1126/Infra-controller.git /home/ec2-user/faas-controller"

# 4. Install NPM Dependencies
su - ec2-user -c "cd /home/ec2-user/faas-controller && npm install"

# 5. Create .env file (Injecting variables)
# Note: In production, fetch from SSM Parameter Store. 
# Here we will write a placeholder or expect Terraform to replace variables.
# For simplicity in this demo, we will rely on Terraform 'templatefile' to fill this.
cat <<EOF > /home/ec2-user/faas-controller/.env
PORT=8080
AWS_REGION=${aws_region}
SQS_URL=${sqs_url}
BUCKET_NAME=${bucket_name}
TABLE_NAME=${table_name}
REDIS_HOST=${redis_host}
REDIS_PORT=6379
INFRA_API_KEY=test-api-key
AWS_ACCESS_KEY_ID=${aws_access_key}
AWS_SECRET_ACCESS_KEY=${aws_secret_key}
EOF
chown ec2-user:ec2-user /home/ec2-user/faas-controller/.env

# 6. Start Service (using PM2 for process management)
npm install -g pm2
su - ec2-user -c "cd /home/ec2-user/faas-controller && pm2 start controller.js --name faas-controller"
su - ec2-user -c "pm2 save"
pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save
