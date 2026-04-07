# ContractorLens Deployment Guide

## 🚀 **Overview**

This guide covers the complete deployment process for ContractorLens, including infrastructure setup, containerization, and production scaling.

---

## 🏗️ **Infrastructure Architecture**

### **Production Stack**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   API Gateway    │    │   CDN (CloudFront)│
│   (AWS ALB)     │    │   (Kong)         │    │   (Static Assets) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ECS Cluster   │
                    │   (Fargate)     │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │ Backend API │ │
                    │ │ (Node.js)   │ │
                    │ └─────────────┘ │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │ Gemini      │ │
                    │ │ Service     │ │
                    │ │ (Node.js)   │ │
                    │ └─────────────┘ │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │ Nginx       │ │
                    │ │ Proxy       │ │
                    │ └─────────────┘ │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   RDS Aurora   │
                    │   PostgreSQL   │
                    └─────────────────┘
```

### **Infrastructure Components**

#### **Compute Layer**
- **ECS Fargate**: Serverless container execution
- **Auto Scaling**: 2-10 instances based on CPU utilization
- **Multi-AZ**: High availability across availability zones

#### **Database Layer**
- **Amazon RDS Aurora**: PostgreSQL-compatible
- **Read Replicas**: 2 read replicas for scaling
- **Automated Backups**: Daily backups with 30-day retention

#### **Storage & CDN**
- **Amazon S3**: Static asset storage
- **CloudFront**: Global CDN for assets
- **S3 Glacier**: Long-term backup storage

#### **Security**
- **AWS WAF**: Web application firewall
- **AWS Shield**: DDoS protection
- **VPC**: Isolated network environment
- **Security Groups**: Fine-grained access control

---

## 📦 **Containerization**

### **Docker Images**

#### **Backend API Image**
```dockerfile
# backend/Dockerfile
FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache \
    postgresql-client \
    redis \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile --production=false

# Copy source code
COPY . .

# Build application
RUN yarn build

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Change ownership
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["yarn", "start:prod"]
```

#### **Gemini Service Image**
```dockerfile
# ml-services/gemini-service/Dockerfile
FROM node:18-alpine

# Install Python for potential ML dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership and permissions
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD node healthcheck.js

# Start service
CMD ["npm", "start"]
```

#### **Nginx Proxy Image**
```dockerfile
# nginx/Dockerfile
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl/ /etc/nginx/ssl/

# Copy static files
COPY static/ /usr/share/nginx/html/

# Create non-root user
RUN addgroup -g 1001 -S nginx
RUN adduser -S nginx -u 1001 -G nginx

# Change ownership
RUN chown -R nginx:nginx /var/cache/nginx
RUN chown -R nginx:nginx /var/log/nginx
RUN chown -R nginx:nginx /etc/nginx/ssl
RUN touch /var/run/nginx.pid
RUN chown nginx:nginx /var/run/nginx.pid

USER nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Expose ports
EXPOSE 80 443
```

### **Multi-Stage Builds**
```dockerfile
# Optimized multi-stage build for backend
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Build the app
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN yarn build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

---

## ☁️ **AWS Infrastructure Setup**

### **Prerequisites**
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install kubectl (for EKS if needed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### **Terraform Configuration**

#### **Main Infrastructure**
```hcl
# infrastructure/terraform/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "contractor-lens-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"

  name = "contractor-lens-prod"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
}

# ECS Cluster
module "ecs" {
  source = "./modules/ecs"

  name = "contractor-lens-prod"

  container_insights = true

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}

# RDS Aurora
module "rds" {
  source = "./modules/rds"

  name           = "contractor-lens-prod"
  engine         = "aurora-postgresql"
  engine_version = "15.4"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  instance_class = "db.r6g.large"
  instances = {
    one = {}
    two = {}
  }

  database_name = "contractorlens"
  master_username = var.db_master_username
  master_password = var.db_master_password

  backup_retention_period = 30
  preferred_backup_window = "03:00-04:00"
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  name = "contractor-lens-prod"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.vpc.default_security_group_id]

  target_groups = [
    {
      name             = "backend"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"
    },
    {
      name             = "gemini"
      backend_protocol = "HTTP"
      backend_port     = 3001
      target_type      = "ip"
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = aws_acm_certificate.cert.arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
}

# CloudFront Distribution
module "cloudfront" {
  source = "./modules/cloudfront"

  name = "contractor-lens-prod"

  origins = {
    s3 = {
      domain_name = module.s3.bucket_regional_domain_name
      origin_id   = "s3-origin"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    forward_cookies = "none"
    forward_headers = []
    forward_query_string = false
  }

  viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}
```

#### **ECS Service Configuration**
```hcl
# infrastructure/terraform/modules/ecs/main.tf

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Backend Service
resource "aws_ecs_service" "backend" {
  name            = "${var.name}-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 100
  }

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_iam_role_policy_attachment.ecs]
}

# Gemini Service
resource "aws_ecs_service" "gemini" {
  name            = "${var.name}-gemini"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.gemini.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 100
  }

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.gemini.arn
  }

  depends_on = [aws_iam_role_policy_attachment.ecs]
}
```

#### **Task Definitions**
```hcl
# Backend Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:latest"

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "PORT", value = "3000" },
        { name = "DATABASE_URL", value = var.database_url },
        { name = "GEMINI_API_KEY", value = var.gemini_api_key },
        { name = "REDIS_URL", value = var.redis_url }
      ]

      secrets = [
        { name = "JWT_SECRET", valueFrom = aws_secretsmanager_secret.jwt_secret.arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
      }
    }
  ])
}
```

---

## 🚀 **Deployment Process**

### **1. Infrastructure Deployment**
```bash
# Initialize Terraform
cd infrastructure/terraform
terraform init

# Plan deployment
terraform plan -var-file=production.tfvars

# Apply infrastructure
terraform apply -var-file=production.tfvars
```

### **2. Database Setup**
```bash
# Connect to RDS instance
psql -h $(terraform output rds_endpoint) -U $(terraform output rds_username) -d contractorlens

# Run migrations
cd database/migrations
psql -h $(terraform output rds_endpoint) -U $(terraform output rds_username) -d contractorlens -f V1__initial_schema.sql
psql -h $(terraform output rds_endpoint) -U $(terraform output rds_username) -d contractorlens -f V2__add_professional_estimate_tables.sql

# Seed data
cd database/seeds
psql -h $(terraform output rds_endpoint) -U $(terraform output rds_username) -d contractorlens -f assemblies.sql
psql -h $(terraform output rds_endpoint) -U $(terraform output rds_username) -d contractorlens -f location_modifiers.sql
```

### **3. Container Deployment**
```bash
# Build and push Docker images
cd backend
docker build -t contractor-lens-backend:latest .
docker tag contractor-lens-backend:latest $(terraform output ecr_backend_url):latest
docker push $(terraform output ecr_backend_url):latest

cd ../ml-services/gemini-service
docker build -t contractor-lens-gemini:latest .
docker tag contractor-lens-gemini:latest $(terraform output ecr_gemini_url):latest
docker push $(terraform output ecr_gemini_url):latest

# Update ECS services
aws ecs update-service --cluster $(terraform output ecs_cluster_name) --service $(terraform output ecs_backend_service_name) --force-new-deployment
aws ecs update-service --cluster $(terraform output ecs_cluster_name) --service $(terraform output ecs_gemini_service_name) --force-new-deployment
```

### **4. SSL Certificate Setup**
```bash
# Request SSL certificate
aws acm request-certificate \
  --domain-name api.contractorlens.com \
  --validation-method DNS \
  --subject-alternative-names "*.contractorlens.com"

# Add DNS validation records
# (AWS Console or Route53 commands)

# Verify certificate
aws acm describe-certificate --certificate-arn $(terraform output acm_certificate_arn)
```

### **5. DNS Configuration**
```bash
# Update Route53 records
aws route53 change-resource-record-sets \
  --hosted-zone-id $(terraform output route53_zone_id) \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "api.contractorlens.com",
          "Type": "A",
          "AliasTarget": {
            "DNSName": "$(terraform output alb_dns_name)",
            "HostedZoneId": "$(terraform output alb_zone_id)",
            "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }'
```

---

## 📊 **Monitoring & Observability**

### **CloudWatch Dashboards**
```json
// monitoring/cloudwatch/dashboard.json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "contractor-lens-backend", "ClusterName", "contractor-lens-prod"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "ECS Service Metrics",
        "period": 300
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "fields @timestamp, @message | sort @timestamp desc | limit 100",
        "logGroupNames": ["/ecs/contractor-lens-backend"],
        "title": "Application Logs",
        "region": "us-east-1"
      }
    }
  ]
}
```

### **Prometheus Configuration**
```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'backend'
    static_configs:
      - targets: ['backend:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'gemini-service'
    static_configs:
      - targets: ['gemini:3001']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']
    scrape_interval: 30s
```

### **Grafana Dashboards**
```json
// monitoring/grafana/dashboard.json
{
  "dashboard": {
    "title": "ContractorLens Production",
    "tags": ["production", "contractor-lens"],
    "timezone": "UTC",
    "panels": [
      {
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"backend\"}[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\", job=\"backend\"}[5m]) / rate(http_requests_total{job=\"backend\"}[5m]) * 100",
            "legendFormat": "Error rate %"
          }
        ]
      }
    ]
  }
}
```

---

## 🔄 **CI/CD Pipeline**

### **GitHub Actions Workflow**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  ECR_BACKEND: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/contractor-lens-backend
  ECR_GEMINI: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/contractor-lens-gemini

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linting
        run: npm run lint

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push backend image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          docker build -t $ECR_BACKEND:latest ./backend
          docker push $ECR_BACKEND:latest

      - name: Build and push gemini image
        run: |
          docker build -t $ECR_GEMINI:latest ./ml-services/gemini-service
          docker push $ECR_GEMINI:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster contractor-lens-prod --service contractor-lens-backend --force-new-deployment
          aws ecs update-service --cluster contractor-lens-prod --service contractor-lens-gemini --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable --cluster contractor-lens-prod --services contractor-lens-backend contractor-lens-gemini

      - name: Run health checks
        run: |
          curl -f https://api.contractorlens.com/health || exit 1
```

---

## 🔧 **Maintenance & Operations**

### **Backup Strategy**
```bash
# Daily database backup
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier contractor-lens-prod \
  --db-cluster-snapshot-identifier "backup-$(date +%Y%m%d-%H%M%S)"

# Automated cleanup (keep last 30 days)
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier contractor-lens-prod \
  --query 'DBClusterSnapshots[?SnapshotCreateTime<`$(date -d "30 days ago" +%Y-%m-%d)`].[DBClusterSnapshotIdentifier]' \
  --output text | xargs -I {} aws rds delete-db-cluster-snapshot --db-cluster-snapshot-identifier {}
```

### **Scaling Policies**
```hcl
# Auto scaling for backend service
resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

### **Security Updates**
```bash
# Automated security patching
aws ecs update-service \
  --cluster contractor-lens-prod \
  --service contractor-lens-backend \
  --force-new-deployment \
  --task-definition $(aws ecs describe-task-definition --task-definition contractor-lens-backend | jq -r '.taskDefinition.revision + 1')
```

---

## 🚨 **Disaster Recovery**

### **Multi-Region Failover**
```hcl
# Secondary region configuration
module "dr_region" {
  providers = {
    aws = aws.dr
  }
  source = "./modules/infrastructure"

  name = "contractor-lens-dr"
  region = "us-west-2"

  # Reduced capacity for DR
  backend_instances = 1
  gemini_instances  = 1
}
```

### **Backup Recovery**
```bash
# Restore from snapshot
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier contractor-lens-dr \
  --snapshot-identifier contractor-lens-prod-snapshot \
  --db-cluster-parameter-group-name contractor-lens-dr

# Switch DNS to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "api.contractorlens.com",
          "Type": "A",
          "AliasTarget": {
            "DNSName": "$(terraform output dr_alb_dns_name)",
            "HostedZoneId": "$(terraform output dr_alb_zone_id)",
            "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }'
```

---

## 📊 **Performance Optimization**

### **Database Optimization**
```sql
-- Create performance indexes
CREATE INDEX CONCURRENTLY idx_estimates_created_at ON estimates (created_at DESC);
CREATE INDEX CONCURRENTLY idx_estimates_user_id ON estimates (user_id);
CREATE INDEX CONCURRENTLY idx_scans_status ON scans (status);

-- Partition large tables
CREATE TABLE estimates_y2024 PARTITION OF estimates
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Optimize queries
EXPLAIN ANALYZE
SELECT * FROM estimates
WHERE created_at >= '2024-01-01'
  AND user_id = $1
ORDER BY created_at DESC
LIMIT 20;
```

### **Caching Strategy**
```javascript
// Redis caching for frequently accessed data
const cache = require('redis').createClient();

class CacheManager {
  async getMaterials() {
    const cached = await cache.get('materials');
    if (cached) return JSON.parse(cached);

    const materials = await db.query('SELECT * FROM materials');
    await cache.setex('materials', 3600, JSON.stringify(materials));
    return materials;
  }

  async invalidateMaterials() {
    await cache.del('materials');
  }
}
```

### **CDN Optimization**
```json
// CloudFront behavior configuration
{
  "CacheBehaviors": [
    {
      "PathPattern": "/api/materials/*",
      "TargetOriginId": "api-origin",
      "ViewerProtocolPolicy": "https-only",
      "CachePolicyId": "api-cache-policy",
      "Compress": true
    },
    {
      "PathPattern": "/static/*",
      "TargetOriginId": "s3-origin",
      "ViewerProtocolPolicy": "https-only",
      "CachePolicyId": "static-cache-policy",
      "Compress": true
    }
  ]
}
```

---

## 📞 **Support & Troubleshooting**

### **Common Issues**

#### **ECS Service Deployment Failures**
```bash
# Check service events
aws ecs describe-services --cluster contractor-lens-prod --services contractor-lens-backend

# Check task definition
aws ecs describe-task-definition --task-definition contractor-lens-backend

# View container logs
aws logs tail /ecs/contractor-lens-backend --follow
```

#### **Database Connection Issues**
```bash
# Test database connectivity
psql -h $(terraform output rds_endpoint) -U $(terraform output rds_username) -d contractorlens

# Check security groups
aws ec2 describe-security-groups --group-ids $(terraform output rds_security_group_id)

# Verify VPC configuration
aws ec2 describe-subnets --subnet-ids $(terraform output private_subnet_ids)
```

#### **Load Balancer Issues**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn $(terraform output backend_target_group_arn)

# View access logs
aws s3 ls s3://contractor-lens-logs/ --recursive | grep access
```

### **Monitoring Alerts**
```hcl
# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "contractor-lens-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.backend.name
  }
}
```

---

**For additional support, contact the DevOps team at [devops@contractorlens.com](mailto:devops@contractorlens.com) or create an issue in the [infrastructure repository](https://github.com/mirzaik-wcc/ContractorLens-infrastructure).**