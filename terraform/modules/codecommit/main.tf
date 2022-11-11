
data "aws_caller_identity" "current" {}
resource "aws_codecommit_repository" "codecommit_repo" {
  repository_name = "${var.general_namespace}_test_code_repo"
  default_branch  = "${var.codecommit_branch}"
  description     = "Application source code repo for lambda ${var.general_namespace}"
}