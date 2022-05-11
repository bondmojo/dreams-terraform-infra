variable "name" {}
variable "short_name" {}
variable "container_port" {
  default = 8080
}
variable "account_number" {}
variable "region" {}
variable "repository" {}
variable "vpc_id" {}
variable "subnets" {}
variable "cluster_id" {}
variable "task-execution-arn" {}
variable "task-arn" {}
variable "namespace_id" {}
variable "mesh-name" {}
variable "image" {}
variable "env_variables" {
  default = []
}
