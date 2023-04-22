terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
   region = "us-east-1"
}

/*
resource "aws_lambda_function" "serverpy" {
   function_name = "Serverless"

   # The S3 bucket should already exists
   s3_bucket = "bogo-terraform-serverless-serverpy"
   s3_key    = "v${var.app_version}/serverpy.zip"


   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"

   role = aws_iam_role.lambda_execpy.arn
}

*/
// Actual Lambda Waiter Handler
resource "aws_security_group" "lambda-waiter-sg" {
  name        = "LAMBDA-WAITER-${var.cluster_name}"
  description = "Allow egress from Lambda waiter to Landing Page instances for status check"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "lambda-waiter" {
  depends_on       = [data.archive_file.lambda_waiter_handler]
  
  function_name    = "Serverless"
  role             = aws_iam_role.lambda-waiter-role.arn
  handler          = "lambda_waiter_callback.handler"
  
  s3_bucket = "bogo-terraform-serverless-serverpy"
  s3_key    = "v${var.app_version}/serverpy.zip"
  runtime          = "python3.8"
  timeout          = "650" #Ensure that max_delay_sec in lambda_waiter_callback is slightly less than this number
  description      = "Wait for URL HTTP 200 before sending status to SC CFN stack"

  vpc_config {
    security_group_ids = [aws_security_group.lambda-waiter-sg.id]
    subnet_ids         = data.aws_subnet_ids.primary.ids
  }
}

 # IAM role which dictates what other AWS services the Lambda function may access.
resource "aws_iam_role" "lambda_execpy" {
   name = "serverless_example_lambdapy"

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

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.serverpy.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.serverpy.execution_arn}/*/*"
}
