# AWSプロバイダーの設定
# リージョンは変数から取得
provider "aws" {
  region = var.aws_region
}

# Terraformのバージョンと必要なプロバイダーの設定
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}