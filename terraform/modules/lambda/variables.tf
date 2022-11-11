variable "ecr_repo_arn" {
    type = string
}

variable "env_namespace" {
    type = string
}

variable "ecr_repo_url" {
    type = string
    description = "Value is coming from tfvars file that is being updated by buildspec environment variables"
}
