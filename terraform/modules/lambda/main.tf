
resource "aws_lambda_function" "this" {
    function_name   = "${var.env_namespace}_lambda"
    handler         = "aws-lambda-url.lambda_handler"
    runtime         = "python3.8"
    memory_size     = null
    # Initial image has to be set, without setting it, it will fail when apply.
    # this will be replaced when build an image from CodeBuild
    # image_uri       = "public.ecr.aws/lambda/python:3.8"
    image_uri       = "${var.ecr_repo_url}:latest"
    package_type    = "Image"
    timeout         = 60
    role            = aws_iam_role.iam_for_lambda.arn
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.env_namespace}_lambda_role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"              
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_for_lambda" {
  role   = aws_iam_role.iam_for_lambda.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "${var.ecr_repo_arn}"
      ],
      "Action": [
        "ecr:*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "ecr:GetAuthorizationToken"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"          
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

