variable "mesh_id" {}
variable "name" {}
variable "namespace" {}
variable "gateway-name" {}
variable "backends" {}
variable "health_check_path" {
  default = "/admin/health"
}
