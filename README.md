# DevOps Assignment — Production-grade Deployment

# Repository

Fork: https://github.com/PG-AGI/DevOps-Assignment

Live URLs (AWS)

1. DEV

    Frontend: https://dev.testingproject.online
    
    Backend: https://api-dev.testingproject.online/api/health

2. STAGING

    Frontend: https://staging.testingproject.online
    
    Backend: https://api-staging.testingproject.online/api/health

3. PROD

    Frontend: https://testingproject.online
    
    Backend: https://api.testingproject.online/api/health

## External Documentation (Google Doc)  

(https://docs.google.com/document/d/1g9gyk9eeOyK0CmHZzsgZfmibkFr6mLrsjSrk6fECJwQ/edit?tab=t.0)

## How to run locally

# Backend

cd backend

python -m venv venv

source venv/bin/activate

pip install -r requirements.txt

uvicorn app.main:app --reload --port 8000

# Frontend

cd frontend

npm install

echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local

npm run dev

# High-level Architecture (AWS)

Frontend: Next.js static export → S3 (origin) → CloudFront (CDN) → custom domain + TLS

Backend: FastAPI container → ECS Fargate (private subnets) behind ALB (HTTPS)

Images: ECR

DNS: Route 53

TLS: ACM (us-east-1 for CloudFront, ap-south-1 for ALB)

Observability: CloudWatch Logs

Traffic flow

User → CloudFront → S3 (frontend)
Frontend → api-<env>.testingproject.online → ALB → ECS task (FastAPI)

# CI/CD (Two workflows)
1) Infra Deploy (Manual / One-click)

GitHub Actions workflow: AWS Infra Deploy (Terraform)

Trigger: workflow_dispatch

Select env: dev/staging/prod

Runs: terraform init + terraform apply

2) App Deploy (Automatic)

GitHub Actions workflow: AWS App Deploy (ECS + S3)

Trigger: push to dev, staging, main

Backend: build/push image to ECR → new task definition revision → update ECS service

Frontend: build export → upload to S3 → CloudFront invalidation

# IaC & State

Terraform used for infra

Remote state stored in S3

Separate state per environment (dev/staging/prod)
