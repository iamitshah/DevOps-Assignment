terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = "ap-south-1" }

locals {
  env             = "staging"
  root_domain     = "testingproject.online"
  frontend_domain = "staging.testingproject.online"
  api_domain      = "api-staging.testingproject.online"

  app_name       = "devops-assignment"
  container_port = 8000

  cpu           = 256
  memory        = 512
  desired_count = 1
}


module "vpc" {
  source = "../../modules/vpc"
  name   = "${local.app_name}-${local.env}"
  cidr   = "10.10.0.0/16"
}

module "dns_acm" {
  source          = "../../modules/dns_acm"
  root_domain     = local.root_domain
  frontend_domain = local.frontend_domain
  api_domain      = local.api_domain
}

module "frontend" {
  source         = "../../modules/s3_cloudfront_frontend"
  name           = "${local.app_name}-${local.env}"
  domain_name    = local.frontend_domain
  acm_cert_arn   = module.dns_acm.frontend_cert_arn
  hosted_zone_id = module.dns_acm.zone_id
}

module "backend" {
  source             = "../../modules/ecs_backend"
  name               = "${local.app_name}-${local.env}"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  hosted_zone_id = module.dns_acm.zone_id
  api_domain     = local.api_domain
  acm_cert_arn   = module.dns_acm.api_cert_arn

  container_port = local.container_port
  cpu            = local.cpu
  memory         = local.memory
  desired_count  = local.desired_count

  initial_image = "public.ecr.aws/docker/library/python:3.11-slim"
  env_vars      = { "APP_ENV" = local.env }
}

output "dev_bucket" { value = module.frontend.bucket_name }
output "dev_cloudfront_id" { value = module.frontend.cloudfront_id }
output "dev_ecr_repo_url" { value = module.backend.ecr_repo_url }
output "dev_ecs_cluster" { value = module.backend.ecs_cluster_name }
output "dev_ecs_service" { value = module.backend.ecs_service_name }
output "dev_task_family" { value = module.backend.task_family }

