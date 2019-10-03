# Variables
variable "myregion" {}

variable "accountId" {}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}


# API Gateway
resource "aws_api_gateway_rest_api" "gumball_machine_api" {
  name = "GumballMachineAPI"
}

resource "aws_api_gateway_resource" "add_gumball" {
  path_part   = "addGumball"
  parent_id   = "${aws_api_gateway_rest_api.gumball_machine_api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.gumball_machine_api.id}"
}

resource "aws_api_gateway_method" "addGumball" {
  rest_api_id   = "${aws_api_gateway_rest_api.gumball_machine_api.id}"
  resource_id   = "${aws_api_gateway_resource.add_gumball.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gumball_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.gumball_machine_api.id}"
  resource_id             = "${aws_api_gateway_resource.add_gumball.id}"
  http_method             = "${aws_api_gateway_method.addGumball.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.myregion}:lambda:path/2015-03-31/functions/${aws_lambda_function.gumball_to_queue_lambda.arn}/invocations"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.gumball_to_queue_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.gumball_machine_api.id}/*/${aws_api_gateway_method.addGumball.http_method}${aws_api_gateway_resource.add_gumball.path}"
}

resource "aws_lambda_function" "gumball_to_queue_lambda" {
  filename      = "lambdas.zip"
  function_name = "gumball_to_queue"
  role          = "${aws_iam_role.gumball_role.arn}"
  handler       = "lambdas/gumball-to-queue.handler"
  runtime       = "nodejs8.10"
  depends_on    = ["aws_iam_role_policy_attachment.sqs_queue_write"]

  source_code_hash = "${filebase64sha256("lambdas.zip")}"

  environment {
    variables = {
        accountId = "${var.accountId}"
        queueName = "${aws_sqs_queue.gumball_queue.name}"
        region =    "${var.myregion}"
    }
  }
}

# IAM
resource "aws_iam_role" "gumball_role" {
  name = "myrole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda_cloudwatch_access" {
  name = "lambda_write_to_cloudwatch"
  path = "/"
  description = "IAM policy allows lambda to write to cloudwatch logs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
                {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "sqs_queue_write" {
  name = "sqs_queue_write"
  path = "/"
  description = "IAM policy for interacting with sqs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "sqs:SendMessageBatch",
                "sqs:SendMessage"
            ],
            "Resource": "arn:aws:sqs:*:*:*"
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_access" {
  role = "${aws_iam_role.gumball_role.name}"
  policy_arn = "${aws_iam_policy.lambda_cloudwatch_access.arn}"
}

resource "aws_iam_role_policy_attachment" "sqs_queue_write" {
  role = "${aws_iam_role.gumball_role.name}"
  policy_arn = "${aws_iam_policy.sqs_queue_write.arn}"
}


resource "aws_sqs_queue" "gumball_queue" {
  name                      = "gumball-example-queue"
  max_message_size          = 2048

  tags = {
    Environment = "production"
  }
}
