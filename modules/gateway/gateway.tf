resource "aws_api_gateway_rest_api" "gojo-api" {
  name        = var.gateway-name
  description = "API gateway for Gojoy App"
  body        = templatefile(var.api-spec, var.api-spec-vars)
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "api-deployment" {
  rest_api_id       = aws_api_gateway_rest_api.gojo-api.id
  stage_description = "Deployed at time 2021-04-17T10:36:17Z"
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.gojo-api.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "api-dev" {
  deployment_id = aws_api_gateway_deployment.api-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.gojo-api.id
  stage_name    = var.env
}
