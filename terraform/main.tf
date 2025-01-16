provider "aws" {
    profile = "default"
    region = "eu-west-2"
}

locals {
    name = "treatwell-movies"
    region = "eu-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "andrew-treatwell"
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

module "ecr_repo" {
    source = "./modules/ecr_repo"
    name = local.name
}

data "archive_file" "init" {
  type        = "zip"
  source_dir = "../code/"
  output_path = "code.zip"
}
#Re-build the docker image if necessary
resource "null_resource" "docker_build_and_push" {
  triggers = {
    dockerfile_hash = filemd5("../dockerfile")
    src_hash = "${data.archive_file.init.output_sha}"
  }

  provisioner "local-exec" {
    command = <<EOT
        aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${module.ecr_repo.repository_url}
        docker build -t ${module.ecr_repo.repository_url}:latest -f ../dockerfile ..
        docker push ${module.ecr_repo.repository_url}:latest
        aws lambda update-function-code --function-name ${local.name} --image-uri ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.name}:latest
    EOT
  }
}

module "lambda_role" {
    source = "./modules/lambda_role"
    lambda_name = local.name
    region = local.region
    account_id = data.aws_caller_identity.current.account_id
    bucket = aws_s3_bucket.bucket.bucket
}

module "lambda" {
    source = "./modules/lambda"
    depends_on = [null_resource.docker_build_and_push]
    description = "treatwell movie lambda"
    image_name = local.name
    docker_entrypoint = "main.lambda_handler"
    account_id = data.aws_caller_identity.current.account_id
    region = local.region
    lambda_name = "treatwell-movies"
    lambda_role = module.lambda_role.lambda_role
    lambda_memory_size = 512
    lambda_timeout = 300
}

module "lambda_eventbridge" {
    source = "./modules/lambda_eventbridge"
    depends_on = [module.lambda]
    lambda_arn = module.lambda.lambda_arn
    lambda_name = local.name
}