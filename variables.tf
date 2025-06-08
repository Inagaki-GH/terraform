# AWSリソースをデプロイするリージョン
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

# アプリケーション名（各リソースの命名に使用）
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "web-app"
}

# アプリケーションがリッスンするポート
variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

# 実行するコンテナの数
variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 2
}

# Fargateタスクに割り当てるCPUユニット
variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 256
}

# Fargateタスクに割り当てるメモリ
variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = number
  default     = 512
}

# VPCのCIDRブロック
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# パブリックサブネットのCIDRブロック
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# プライベートサブネットのCIDRブロック
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# アプリケーションのドメイン名（ACM証明書とRoute53に使用）
# 注意: このドメインはRoute53で管理されている必要があります
# terraform applyを実行する前に、実際に所有しているドメインに変更してください
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com"  # 実際のドメインに変更してください
}

# ECRリポジトリ名
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "web-app"
}

# ECSで実行するコンテナイメージ（初期デプロイ用）
variable "container_image" {
  description = "Docker image to run in the ECS cluster"
  type        = string
  default     = "nginx:latest"
}