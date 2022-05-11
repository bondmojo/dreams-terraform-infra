resource "aws_api_gateway_vpc_link" "main" {
  name        = "${var.name}-vpc-link"
  description = "Connection to load balancer"
  target_arns = [var.lbarn]
}
