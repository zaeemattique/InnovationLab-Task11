# Node.js CI/CD Pipeline with AWS Services

## Project Overview

This project implements a fully automated CI/CD pipeline for a Node.js application using AWS services. The pipeline automatically builds, tests, and deploys the application to AWS Elastic Beanstalk whenever code changes are pushed to the repository.

## Architecture Components

![alt text](https://raw.githubusercontent.com/zaeemattique/InnovationLab-Task11/refs/heads/main/Task11%20Architecture%20Diagram.drawio.png)

### 1. **Source Control**
- **Service**: GitHub (or CodeCommit/S3)
- **Purpose**: Version control and source code repository
- **Trigger**: Commits to main branch trigger the pipeline automatically

### 2. **CI/CD Pipeline**
- **Service**: AWS CodePipeline
- **Stages**:
  - **Source Stage**: Fetches code from GitHub repository
  - **Build Stage**: Runs CodeBuild to install dependencies and create artifacts
  - **Deploy Stage**: Deploys the application to Elastic Beanstalk

### 3. **Build Service**
- **Service**: AWS CodeBuild
- **Configuration**:
  - Runtime: Node.js 18
  - Build specification: `buildspec.yml`
  - Output: Zipped application artifact stored in S3

### 4. **Hosting Platform**
- **Service**: AWS Elastic Beanstalk
- **Configuration**:
  - Platform: 64bit Amazon Linux 2023 running Node.js 18
  - Instance Type: t3.micro
  - Auto Scaling: Min 2, Max 4 instances
  - Load Balancer: Application Load Balancer (ALB)
  - Health Checks: Enhanced monitoring enabled

### 5. **Networking**
- **VPC**: Custom VPC with public and private subnets
- **Subnets**:
  - Public subnets: For Application Load Balancer
  - Private subnets: For EC2 instances running the application
- **Security Groups**:
  - ALB Security Group: Allows HTTP/HTTPS traffic from internet
  - Instance Security Group: Allows traffic only from ALB

## Architecture Diagram

```
┌─────────────┐
│   GitHub    │
│ Repository  │
└──────┬──────┘
       │ (Code Push)
       ▼
┌─────────────────────────────────────────┐
│        AWS CodePipeline                 │
│  ┌────────────────────────────────┐    │
│  │  Source Stage                  │    │
│  │  - Fetch from GitHub           │    │
│  └─────────────┬──────────────────┘    │
│                ▼                        │
│  ┌────────────────────────────────┐    │
│  │  Build Stage (CodeBuild)       │    │
│  │  - npm install                 │    │
│  │  - Create artifact             │    │
│  └─────────────┬──────────────────┘    │
│                ▼                        │
│  ┌────────────────────────────────┐    │
│  │  Deploy Stage                  │    │
│  │  - Deploy to Elastic Beanstalk │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│    AWS Elastic Beanstalk Environment    │
│  ┌────────────────────────────────┐    │
│  │   Application Load Balancer     │    │
│  │   (Public Subnets)              │    │
│  └─────────────┬──────────────────┘    │
│                ▼                        │
│  ┌────────────────────────────────┐    │
│  │  Auto Scaling Group             │    │
│  │  EC2 Instances (Private)        │    │
│  │  - Min: 2, Max: 4               │    │
│  │  - Node.js 18 Runtime           │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Key Configuration Files

### 1. buildspec.yml
Defines the build process for CodeBuild:

```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
  
  pre_build:
    commands:
      - echo "Installing dependencies..."
      - npm install --production
  
  build:
    commands:
      - echo "Build completed on `date`"
  
  post_build:
    commands:
      - echo "Preparing artifact..."
      
artifacts:
  files:
    - '**/*'
```

### 2. package.json
Node.js application configuration with start script:

```json
{
  "name": "node-js-sample",
  "version": "0.2.0",
  "scripts": {
    "start": "node index.js"
  },
  "engines": {
    "node": "18.x",
    "npm": ">=6.0.0"
  }
}
```

### 3. index.js
Main application file:

```javascript
var express = require('express')
var app = express()
app.set('port', (process.env.PORT || 5000))
app.use(express.static(__dirname + '/public'))
app.get('/', function(request, response) {
  response.send('Hello World!')
})
app.listen(app.get('port'), function() {
  console.log("Node app is running at localhost:" + app.get('port'))
})
```

## IAM Roles and Permissions

### 1. CodePipeline Role
**Permissions**:
- Access to S3 bucket for artifacts
- Start/stop CodeBuild projects
- Deploy to Elastic Beanstalk
- Use CodeStar Connections (for GitHub)
- Create/manage CloudWatch Logs
- Manage ECS tasks and services

### 2. CodeBuild Role
**Permissions**:
- Read/write to S3 artifact bucket
- Push/pull from ECR (if using Docker)
- Create CloudWatch Logs
- Decrypt KMS keys (for encrypted artifacts)

### 3. Elastic Beanstalk Service Role
**Permissions**:
- Manage EC2 instances
- Configure Auto Scaling
- Manage Elastic Load Balancers
- Access CloudFormation
- Write CloudWatch Logs

### 4. EC2 Instance Profile
**Permissions**:
- Read from S3 (application artifacts)
- Write to CloudWatch Logs
- Pull from ECR (if needed)

## Deployment Flow

### Automated Deployment Process

1. **Developer pushes code** to GitHub repository
2. **CodePipeline detects change** via GitHub webhook
3. **Source Stage** downloads latest code
4. **Build Stage** (CodeBuild):
   - Installs Node.js dependencies (`npm install --production`)
   - Creates deployment artifact
   - Uploads artifact to S3
5. **Deploy Stage**:
   - Downloads artifact from S3
   - Updates Elastic Beanstalk environment
   - Performs rolling deployment (50% batch size)
6. **Health Checks**:
   - ALB health checks verify instances are healthy
   - Unhealthy instances are replaced automatically
7. **Application is live** at Elastic Beanstalk environment URL

### Rolling Deployment Strategy

- **Deployment Policy**: Rolling
- **Batch Size**: 50%
- **Min Instances in Service**: 1
- **Health Check Path**: `/`
- **Deregistration Delay**: 20 seconds

This ensures **zero downtime** during deployments.

## Elastic Beanstalk Configuration

### Application Settings

```hcl
# Node.js Port Configuration
PORT = 5000

# Auto Scaling
MinSize = 2
MaxSize = 4
InstanceType = t3.micro

# Load Balancer
Type = Application Load Balancer
Protocol = HTTP
Port = 80

# Health Checks
HealthCheckPath = /
HealthCheckInterval = 30 seconds
HealthyThreshold = 3
UnhealthyThreshold = 5
HealthCheckTimeout = 5 seconds
```

### Enhanced Health Monitoring

- **System Type**: Enhanced
- **CloudWatch Logs**: Enabled
- **Log Streaming**: Enabled
- **Retention**: 7 days

## Infrastructure as Code (Terraform)

The entire infrastructure is defined using Terraform modules:

### Module Structure

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    ├── vpc/
    ├── security_groups/
    ├── iam/
    ├── elastic_beanstalk/
    ├── codebuild/
    └── codepipeline/
```

### Key Resources

- VPC with public/private subnets
- Security groups for ALB and instances
- IAM roles and policies
- Elastic Beanstalk application and environment
- CodeBuild project
- CodePipeline with three stages
- S3 bucket for artifacts
- CodeStar Connection (GitHub integration)

## Monitoring and Logging

### CloudWatch Logs

All application and system logs are streamed to CloudWatch:

- `/aws/elasticbeanstalk/<env>/var/log/eb-engine.log`
- `/aws/elasticbeanstalk/<env>/var/log/web.stdout.log`
- `/aws/elasticbeanstalk/<env>/var/log/nginx/access.log`
- `/aws/elasticbeanstalk/<env>/var/log/nginx/error.log`

### Health Monitoring

- Enhanced health reporting enabled
- Real-time metrics in Elastic Beanstalk console
- ALB target health checks
- Auto Scaling based on CPU/memory thresholds

## Testing and Validation

### Local Testing

```bash
# Install dependencies
npm install

# Run locally
npm start

# Test endpoint
curl http://localhost:5000
```

### Post-Deployment Testing

1. Get Elastic Beanstalk environment URL from AWS Console
2. Test the endpoint:
   ```bash
   curl http://<your-eb-env-url>
   ```
3. Expected response: `Hello World!`

## Triggering Deployments

### Automatic Deployment

Any push to the main branch triggers automatic deployment:

```bash
# Make changes to code
git add .
git commit -m "Update application"
git push origin main
```

### Manual Deployment

You can manually trigger the pipeline in AWS Console:
1. Go to CodePipeline console
2. Select your pipeline
3. Click "Release change"

## Rollback Strategy

### Automatic Rollback

Elastic Beanstalk automatically rolls back if:
- Deployment fails health checks
- Instances fail to start
- Command execution fails

### Manual Rollback

1. Go to Elastic Beanstalk console
2. Select your environment
3. Click "Configuration" → "Rolling updates and deployments"
4. Deploy a previous application version

## Cost Optimization

### Estimated Monthly Costs

- **EC2 Instances** (2x t3.micro): ~$15
- **Application Load Balancer**: ~$20
- **Data Transfer**: Variable
- **CloudWatch Logs**: ~$5
- **S3 Storage**: <$1
- **CodePipeline**: $1/active pipeline
- **CodeBuild**: $0.005/build minute

**Total**: ~$40-50/month

### Cost Saving Tips

- Use t3.micro for development
- Enable Auto Scaling to scale down during off-hours
- Set CloudWatch log retention to 7 days
- Delete old application versions in S3

## Security Best Practices

1. **Least Privilege IAM**: Roles have minimum required permissions
2. **Private Subnets**: Application instances run in private subnets
3. **Security Groups**: Restrictive rules limiting access
4. **HTTPS**: Configure SSL/TLS certificate on ALB (recommended)
5. **Secrets Management**: Use AWS Secrets Manager for sensitive data
6. **Regular Updates**: Keep Node.js and dependencies updated

## Troubleshooting

### Common Issues

#### 1. Deployment Fails
- Check CodeBuild logs for build errors
- Verify `package.json` has correct `start` script
- Ensure `buildspec.yml` is in repository root

#### 2. Health Check Failures
- Verify application listens on `process.env.PORT`
- Check health check path matches application route
- Review security group rules

#### 3. Pipeline Stuck
- Check IAM role permissions
- Verify S3 bucket access
- Review CloudWatch Logs for errors

### Useful Commands

```bash
# View Terraform state
terraform show

# Check pipeline status
aws codepipeline get-pipeline-state --name <pipeline-name>

# View CodeBuild logs
aws logs tail /aws/codebuild/<project-name> --follow

# Describe EB environment
aws elasticbeanstalk describe-environments --environment-names <env-name>
```

## Contributors

- Your Name - Infrastructure and DevOps Implementation
