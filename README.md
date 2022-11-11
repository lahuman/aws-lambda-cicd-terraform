# AWS Lambda CI/CD 
## _using Terraform and CodePipeline_

이 예제는 CodePipeline 및 Terraform을 사용한 지속적인 통합 및 배포를 통해 완벽하게 작동하는 AWS Lambda 샘플 서비스를 설정하는 데 도움이 됩니다.

### 전체 구성도

![](/assets/process_flow.png)

## Prerequiste 

- [AWS Cli](https://aws.amazon.com/cli/)
- [Terraform Cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)  
- [docker](https://docs.docker.com/engine/install/)

## Features

- AWS Lambda Function - [bs4](https://pypi.org/project/beautifulsoup4/)를 활용해서 https://lahuman.github.io 의 title 을 출력
- CI/CD - Complete CodePipeline: [CodeCommit](https://aws.amazon.com/codecommit/), Source, Build, Deploy
- Private [Elastic Container Registry](https://aws.amazon.com/ecr/) for your AWS Lambda Code

## Instruction

프로젝트 Clone 처리

```sh
git clone https://github.com/lahuman/aws-lambda-cicd-terraform.git
cd aws-lambda-cicd-terraform/terraform
```

 `terraform.tfvars` 파일에서 주요 내용 수정

- org_name   = "ORG_NAME"
- team_name  = "TEAM_NAME"
- project_id = "PROJECT_ID"
- region     = "REGION"

`providers.tf` 에서도 region을 `terraform.tfvars`과 동일하게 변경 처리

- region     = "REGION"

```sh
terraform init
terraform apply

# 성공 메시지
....
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
....
```

### 초기 이미지 push 후 ECR 

![](/assets/ecr_repository.png)

성공시 아래와 같은 리소스들이 생성됩니다. 

- iam, role, policy, CodeCommit, Lambda function, CodePipeline, Etc

## 아직 끝나지 않았습니다. 

codeCommit에 코드를 추가해야 합니다. 

### 비어있는 repository

![](/assets/codecommit-repo.png)

```sh
# move to the directory you want to make lambda code project director
git clone https://git-codecommit.${REGION}.amazonaws.com/v1/repos/${ORG_NAME}-${TEAM_NAME}-${PROJECT_ID}_test_code_repo
# copy sample code to repo directory
cp ./aws-lambda-cicd-terraform/lambdacode/* ./${ORG_NAME}-${TEAM_NAME}-${PROJECT_ID}_test_code_repo/
# move to cloned repo directory
cd ${ORG_NAME}-${TEAM_NAME}-${PROJECT_ID}_test_code_repo
# push sample code to repo
git add .
git commit -m "Initial commit"
git push
```

## CICD -빌드 및 배포 준비가 다 되었습니다. 

- AWS 웹 콘솔에서 `CodeCommit`으로 이동하세요.
- `CodePipeline` 메뉴를 클릭하세요.

- `Release` 버튼을 클릭하세요

<img src="assets/codepipeline-detail.png" width="600">

## Checkout updated Lambda

- CodeDeploy는 CodeBuild 단계에서 빌드된 Docker 이미지와 함께 AWS Cli를 사용하여 CodeCommit에 푸시된 소스 코드로 대체합니다.

<img src="assets/lambda.png" width="300">

- `Lambda` 테스트

<img src="assets/lambda-detail.png" width="650">

<img src="assets/lambda-test.png" width="650">

# Lambda 코드 배포 방법에 대해 고려해야 할 사항

- 이미지와 함께 람다를 배포하는 경우 AWS 웹 콘솔에서 직접 코드를 볼 수 없습니다.
- AWS에 람다 코드를 배포하는 다른 방법이 있습니다. 소스 코드를 압축하고 이를 교체하여 람다 코드를 업데이트할 수 있습니다.

## Reference
- https://github.com/aws-samples/codepipeline-for-lambda-using-terraform
- https://www.maxivanov.io/deploy-aws-lambda-to-vpc-with-terraform/

## 2022.11.12 변경 내역

- module 간 의존성 추가 처리

```
module "ecr" {
  source            = "./modules/ecr"
  general_namespace = local.general_namespace
  env_namespace     = local.env_namespace
  default_region    = var.region
  account_id        = data.aws_caller_identity.current.account_id
}

module "lambda" {
  # 이부분을 추가 
  depends_on = [module.ecr] # After completion of module.ecr
  source = "./modules/lambda"
  env_namespace = local.env_namespace
  ecr_repo_arn = module.ecr.ecr_configs.ecr_repo_arn
  ecr_repo_url = module.ecr.ecr_configs.ecr_repo_url
}

# ./module/lambda/main.tf 에 sleep 삭제 처리
# ecr을 생성하고 docker image를 업로드 하는데 약 30초의 시간이 걸립니다. 이를 기다리게 하기 위해서 time_sleep를 사용하였습니다
# 더 좋은 방법이 있을꺼 같은데 찾아봐야겠습니다.
resource "null_resource" "previous" {}
# sleep 40 seconds
resource "time_sleep" "wait_40_seconds" {
  depends_on = [null_resource.previous]
  create_duration = "40s"
}

resource "aws_lambda_function" "this" {
    depends_on = [time_sleep.wait_40_seconds]
    .....
}
```
## 2022.11.11 변경 내역
- local-exec로 초기 이미지 push 처리
```
# ./module/ecr/main.tf 에서 
# local-exec 의 의미가 현재 terraform 을 실행하는 머신에서 실행한다는 의미 입니다.

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

# ./module/lambda/main.tf
# ecr을 생성하고 docker image를 업로드 하는데 약 30초의 시간이 걸립니다. 이를 기다리게 하기 위해서 time_sleep를 사용하였습니다
# 더 좋은 방법이 있을꺼 같은데 찾아봐야겠습니다.
resource "null_resource" "previous" {}
# sleep 40 seconds
resource "time_sleep" "wait_40_seconds" {
  depends_on = [null_resource.previous]
  create_duration = "40s"
}

resource "aws_lambda_function" "this" {
    depends_on = [time_sleep.wait_40_seconds]
    .....
}
```

## 작업에  도움 주신분

- [신필용](https://www.shinphil.com/kr)
- [t101 스터디 멤버](http://t101.cloudneta.net)
    + @지닉-진익현
    + @ddiiwoong - 김진웅