
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_policy" "dynamo_db_readwrite" {
  name = "dynamo_db_readwrite"
  path = "/"
  description = "IAM policy for interacting with dynamodb"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "dynamodb:ListTagsOfResource",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:DescribeLimits",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:DescribeStream",
                "dynamodb:UpdateItem",
                "dynamodb:DescribeTimeToLive",
                "dynamodb:GetRecords"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dynamo_db_readwrite" {
  role = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.dynamo_db_readwrite.arn}"
}

variable "myregion" {}

variable "accountId" {}

resource "aws_api_gateway_rest_api" "sws_api" {
  name = "simple_web_service_api"
}

resource "aws_api_gateway_resource" "add_js_framework_resource" {
  path_part   = "addFramework"
  parent_id   = "${aws_api_gateway_rest_api.sws_api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.sws_api.id}"
}

resource "aws_api_gateway_method" "sws_add_framework_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.sws_api.id}"
  resource_id   = "${aws_api_gateway_resource.add_js_framework_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.sws_api.id}"
  resource_id             = "${aws_api_gateway_resource.add_js_framework_resource.id}"
  http_method             = "${aws_api_gateway_method.sws_add_framework_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.myregion}:lambda:path/2015-03-31/functions/${aws_lambda_function.sws_lambda.arn}/invocations"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sws_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.sws_api.id}/*/${aws_api_gateway_method.sws_add_framework_method.http_method}${aws_api_gateway_resource.add_js_framework_resource.path}"
}


resource "aws_lambda_function" "sws_lambda" {
  filename      = "./lambdas.zip"
  function_name = "simple_web_service_lambda"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "lambdas/sws-lambda.handler"
  depends_on    = ["aws_iam_role_policy_attachment.dynamo_db_readwrite"]

  source_code_hash = "${filebase64sha256("lambdas.zip")}"

  runtime = "nodejs8.10"

  environment {
    variables = {
      TableName = "${aws_dynamodb_table.jsFrameworkListDynamoTable.name}"
    }
  }
}


resource "aws_dynamodb_table" "jsFrameworkListDynamoTable" {
  name           = "JSFrameworks"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "GithubURL"
  range_key      = "Year"

  attribute {
    name = "GithubURL"
    type = "S"
  }

  attribute {
    name = "Year"
    type = "N"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}
