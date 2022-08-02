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
  default = "dm"
}

variable "namespace" {
  default = "co.dreams"
}

variable "name" {
  default = "dreams-app"
}

variable "repository" {
  default = "dreams-service-app"
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
