data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
    arn="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_ecr_repository" "hello_world_ecr" {
  name                 = "hello_world_ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "upload_image_to_ecr" {
  provisioner "local-exec" {
    command = <<EOF
            aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
EOF
  }
}

resource "aws_iam_role" "hello_world_lambda_execution_role" {
  name = "hello_world_lambda_execution_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
  ]
}

resource "aws_lambda_function" "hello_world_lambda" {
  depends_on = [null_resource.upload_image_to_ecr]
  function_name = "hello_world_lambda"
  role = aws_iam_role.hello_world_lambda_execution_role.arn
  image_uri=join(":", [aws_ecr_repository.hello_world_ecr.repository_url, "latest"])
  package_type="Image"
}

# resource "null_resource" "update_hello_world_lambda" {
#   depends_on = [aws_lambda_function.hello_world_lambda]
#   triggers = {
#     python_file = md5(file("./lambdas/hello_world.py"))
#     docker_file = md5(file("./lambdas/Dockerfile"))
#   }
#
#   provisioner "local-exec" {
#     command = <<EOF
#             aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
#             cd lambdas
#             docker build -t ${aws_ecr_repository.hello_world_ecr.name} .
#             docker tag ${aws_ecr_repository.hello_world_ecr.name}:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.hello_world_ecr.name}:latest
#             docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.hello_world_ecr.name}:latest
#             aws lambda update-function-code --function-name ${aws_lambda_function.hello_world_lambda.function_name} --image-uri ${aws_ecr_repository.hello_world_ecr.repository_url}:latest
# EOF
#   }
# }
