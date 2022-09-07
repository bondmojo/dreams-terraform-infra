terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  profile = "devaccess"
  region  = var.region
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnet_ids" "vpc_subnet" {
  vpc_id = data.aws_vpc.vpc.id
}

module "ecs" {
  source     = "./modules/ecs"
  name       = var.name
  short_name = var.short_name
}

module "main-loadbalancer" {
  source = "./modules/loadbalancer"
  name = var.name
  subnets            = data.aws_subnet_ids.vpc_subnet.ids
  vpc_id             = data.aws_vpc.vpc.id
}
module "service-main" {
  source             = "./modules/fargate"
  account_number     = var.account
  region             = var.region
  repository         = var.repository
  name               = "main"
  short_name         = var.short_name
  subnets            = data.aws_subnet_ids.vpc_subnet.ids
  vpc_id             = data.aws_vpc.vpc.id
  cluster_id         = module.ecs.cluster-id
  task-arn           = module.ecs.task-arn
  task-execution-arn = module.ecs.task-execution-arn
  image              = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${var.repository}:latest"
  lb_target_group_id = module.main-loadbalancer.lb_target_group_id
}

module "vpc_link" {
  source = "./modules/vpclink"
  lbarn  = module.main-loadbalancer.lb_arn
  name   = var.name
}

module "gateway" {
  source       = "./modules/gateway"
  gateway-name = "${var.name}-gateway"
  api-spec     = "swagger.yml"
  api-spec-vars = {
    url       = module.main-loadbalancer.lb_url
    vpc-id    = module.vpc_link.vlarn
    accountId = var.account
    region    = var.region
  }
  env = var.env
}
