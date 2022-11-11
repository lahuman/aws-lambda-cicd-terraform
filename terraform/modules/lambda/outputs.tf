output "lambda_configs" {
    value = {
        lambda_role_arn = aws_iam_role.iam_for_lambda.arn
        lambda_name = aws_lambda_function.this.function_name
    }
}