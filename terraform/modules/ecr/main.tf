
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

# resource "null_resource" "local-image" {
#   provisioner "remote-exec" {
#     inline = [
#       "aws ecr get-login-password --region ${var.default_region} | podman login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.default_region}.amazonaws.com",
#       "podman pull public.ecr.aws/lambda/python:3.8",
#       "podman tag public.ecr.aws/lambda/python:3.8 ${var.general_namespace}_test_docker_repo:latest",
#       "podman push ${var.general_namespace}_test_docker_repo:latest"
#     ]
#   }
# }

resource "null_resource" "docker_build" { 
  # on Terraform Running Machine
  provisioner "local-exec" {
    interpreter = ["bash", "-c"] 
    command = <<-EOT
      aws ecr get-login-password --region ${var.default_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.default_region}.amazonaws.com
      docker pull public.ecr.aws/lambda/python:3.8
      docker tag public.ecr.aws/lambda/python:3.8 ${var.account_id}.dkr.ecr.${var.default_region}.amazonaws.com/${var.general_namespace}_test_docker_repo:latest
      docker push ${var.account_id}.dkr.ecr.${var.default_region}.amazonaws.com/${var.general_namespace}_test_docker_repo:latest
      EOT
  }
}
