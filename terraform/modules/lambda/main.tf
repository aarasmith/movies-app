
resource "aws_lambda_function" "lambda" {
    description = var.description
    architectures = ["arm64"]
    package_type = "Image"
    function_name = var.lambda_name
    image_uri = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.image_name}:latest"
    # handler = "lambda_function.lambda_handler"
    role = "arn:aws:iam::${var.account_id}:role/service-role/${var.lambda_role.name}"
    memory_size = var.lambda_memory_size
    timeout = var.lambda_timeout

    # environment {
    #     variables = {

    #     }
    # }

    image_config {
        command = [var.docker_entrypoint]
    }

    ephemeral_storage {
        size = 512
    }

    # vpc_config {
    #     security_group_ids = [
    #         var.sg_id
    #     ]
    #     subnet_ids = [for id in var.subnet_ids : id]
    # }
}

resource "aws_cloudwatch_log_group" "lambda" {
    name = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
    retention_in_days = 90
    lifecycle {
        create_before_destroy = true
        prevent_destroy = false
    }
}