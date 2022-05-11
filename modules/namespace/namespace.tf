resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.namespace}.local"
  description = "Namespace for services (Terraform managed)"
  vpc = var.vpc_id
}
