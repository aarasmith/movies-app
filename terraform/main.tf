locals {
    name = "treatwell-movies"
    region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-treatwell"
    key    = "movies"
    region = "eu-west-2"
  }
}

provider "aws" {
    profile = "default"
    region = "eu-west-2"
}

#for use as the account_id arg in various modules
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "andrew-treatwell"
}

module "ecr_repo" {
    source = "./modules/ecr_repo"
    name = local.name
}

#zip the code so we can check the hash to determine if image re-build is necessary
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
    account_id = data.aws_caller_identity.current.account_id
    region = local.region
    description = "treatwell movie lambda"
    lambda_name = local.name
    image_name = local.name
    lambda_architecture = "arm64"
    docker_entrypoint = "main.lambda_handler"
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