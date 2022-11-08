data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "null_resource" "upload_image_to_ecr" {
    provisioner "local-exec" {
      command = <<EOF
          aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      EOF
    }
}
