# Movies App

This application ingests API data from `https://api.sampleapis.com/movies/` for all categories available every morning at 1am GMT and stores them as individual json files in an S3 bucket.

## Deployment
First, create an S3 bucket to serve as the backend for the terraform project (`terraform-treatwell` by default). This can be altered at the top of the `main.tf` file in the `terraform` folder.

Ensure that you have properly configured the appropriate AWS credentials on the deployment system before running. After that, navigate to the terraform folder and run `terraform init`, followed by `terraform plan` and `terraform apply`.

Upon changes to any of the code within the `code` folder or the dockerfile, the image will be re-built and the lambda function updated upon running the TF project again. If there are no changes, the docker image will not be re-built.

This should probably be handled in a CI/CD pipeline, but I write terraform for fun and CI/CD only when I'm getting paid :)

## Components
The code for the application can be found in the `code` folder. It consists of a single `main.py` file

The `terraform` folder contains a `main.tf` file, which is the primary tf file used for building the infrastructure, as well as subfolders for each module. The infra consists of:

    - An ECR repo for hosting the containerized application
    - A docker-image-based lambda function that runs the application's `main()` function upon invocation
    - A lambda execution-role and attached policies following the principle of least priviledge
    - An eventbridge mapping to trigger the lambda daily at 1am GMT

These modules are called in the top-level `main.tf` file. Certain parameter changes can be passed as arguments. If you desire to make changes to the configuration, please first check to see if you can alter these arguments before making changes to the modules' `main.tf` files. The arguments can be found in each module's respective `variables.tf` file.

**NOTE** The lambda architecture is arm64 as this was developed on a silicon apple system. If building the docker image on an amd64 system, please alter the `lambda_architecture` argument to the `lambda` module found in `terraform/main.tf` to `x86_64`

## Testing
A few unittests can be found in the `code/tests` folder. You can run these by navigating into the `code` folder and running `python3 -m unittest discover .` or however you prefer to invoke the unittest module.
