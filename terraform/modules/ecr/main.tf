
data "aws_caller_identity" "current" {}
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.general_namespace}_test_docker_repo"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    env = var.env_namespace
  }
}

# resource "null_resource" "docker_build" {
  
#  provisioner "local-exec" {
#     command = <<-EOT
#       docker pull public.ecr.aws/lambda/python:3.8
#       docker tag public.ecr.aws/lambda/python:3.8 ${var.general_namespace}_test_docker_repo:latest
#       docker push ${var.general_namespace}_test_docker_repo:latest
#       EOT
#     }
# }