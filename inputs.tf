variable "region"{
  default = "ap-southeast-1"
}

variable "env" {
  default = "prod"
}

variable "account" {
  default = "987547247766"
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
  default = "vpc-0ef7ad80aecc1861a"
}

variable "vpc_subnet" {
  default = ["subnet-0f1fc983769a90775", "subnet-0c5743f5d15769ddb"]
}

variable "dbname" {
  default = "dreams-db"
}

variable "logiq" {
  default = "gj.logiq.ai"
}
