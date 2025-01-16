resource "aws_iam_role" "lambda_role" {
    name = "Role_${var.lambda_name}"
    path = "/service-role/"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = "RequiredAccessForMoviesLambda"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy" "lambda_policy_log" {
    name = "Policy_${var.lambda_name}_log"
    role = aws_iam_role.lambda_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:PutLogEvents",
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream"
                ]
                Effect = "Allow"
                Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
            }
        ]
    })
}

resource "aws_iam_role_policy" "lambda_policy_log_group" {
    name = "Policy_${var.lambda_name}_log_group"
    role = aws_iam_role.lambda_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Effect = "Allow"
                Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${var.lambda_name}:*"
            },
            {
                Effect = "Allow",
                Action = [
                    "logs:CreateLogGroup"
                ]
                Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
            }
        ]
    })
}

resource "aws_iam_role_policy" "lambda_policy_bucket" {
    name = "Policy_${var.lambda_name}_bucket_access"
    role = aws_iam_role.lambda_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ]
                Effect = "Allow"
                Resource = [
                    "arn:aws:s3:::${var.bucket}/*",
                    "arn:aws:s3:::${var.bucket}"
                ]
            }
        ]
    })
}