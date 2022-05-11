variable "region"{
  default = "ap-southeast-1"
}

variable "env" {
  default = "dev"
}

variable "account" {
  default = "596917627629"
}

variable "short_name" {
  default = "gy"
}

variable "namespace" {
  default = "co.gojoy"
}

variable "name" {
  default = "gojoy-app"
}

variable "repository" {
  default = "gojoy-service-app"
}

variable "hasura_image" {
  default = "hasura/graphql-engine:v2.6.0"
}

variable "vpc_id" {
  default = "vpc-04c79016177929144"
}

variable "vpc_subnet" {
  default = ["subnet-0fb70f5227a9fb003", "subnet-0b8137edef1a8fb3d"]
}

variable "dbname" {
  default = "sejaya-neobank-db"
}

variable "logiq" {
  default = "gj.logiq.ai"
}
