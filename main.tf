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

data "aws_db_instance" "db" {
  db_instance_identifier = var.dbname
}

module "ecs" {
  source     = "./modules/ecs"
  name       = var.name
  short_name = var.short_name
}

module "namespace" {
  source    = "./modules/namespace"
  namespace = var.namespace
  vpc_id    = data.aws_vpc.vpc.id
}

module "app-mesh" {
  source = "./modules/mesh"
  name   = var.name
}

module "mesh-gateway" {
  source  = "./modules/mesh-gateway"
  mesh_id = module.app-mesh.id
  name    = var.name
}


module "mesh-ext-mod-database" {
  source    = "./modules/mesh-external-reference"
  mesh_id   = module.app-mesh.id
  host_port = 5432
  hostname  = data.aws_db_instance.db.address
  name      = "database"
}

module "mesh-ext-mod-logengine" {
  source    = "./modules/mesh-external-reference"
  mesh_id   = module.app-mesh.id
  host_port = 443
  hostname  = var.logiq
  name      = "logengine"
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
  namespace_id       = module.namespace.namespace_id
  mesh-name          = module.app-mesh.id
  image              = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${var.repository}:latest"
}

module "service-main-virtual-service" {
  source       = "./modules/mesh-service"
  mesh_id      = module.app-mesh.id
  name         = "main"
  namespace    = module.namespace.namespace_name
  gateway-name = module.mesh-gateway.name
  backends     = [module.mesh-ext-mod-database.name]
}

module "service-virtual-gateway" {
  source             = "./modules/mesh-gateway-fargate"
  account_number     = var.account
  region             = var.region
  name               = var.name
  subnets            = data.aws_subnet_ids.vpc_subnet.ids
  vpc_id             = data.aws_vpc.vpc.id
  cluster_id         = module.ecs.cluster-id
  task-arn           = module.ecs.task-arn
  task-execution-arn = module.ecs.task-execution-arn
  namespace_id       = module.namespace.namespace_id
  mesh-name          = module.app-mesh.id
}

module "vpc_link" {
  source = "./modules/vpclink"
  lbarn  = module.service-virtual-gateway.lb-arn
  name   = var.name
}

module "gateway" {
  source       = "./modules/gateway"
  gateway-name = "${var.name}-gateway"
  api-spec     = "swagger.yml"
  api-spec-vars = {
    url       = module.service-virtual-gateway.lb-url
    vpc-id    = module.vpc_link.vlarn
    accountId = var.account
    region    = var.region
  }
  env = var.env
}
