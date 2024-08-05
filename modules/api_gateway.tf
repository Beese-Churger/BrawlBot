resource "aws_api_gateway_rest_api" "brawlbot_api" {
  name        = "BrawlbotAPI"
  description = "API endpoint for Brawlbot"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.brawlbot_api.id
  resource_id   = aws_api_gateway_rest_api.brawlbot_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.brawlbot_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.brawlbot-main.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root
  ]

  rest_api_id = aws_api_gateway_rest_api.brawlbot_api.id
  stage_name  = "test"
}
