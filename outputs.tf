# ALBのDNS名
# 直接ALBにアクセスする場合に使用
output "alb_hostname" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the load balancer"
}

# ウェブサイトのURL
# HTTPSプロトコルとドメイン名を組み合わせたURL
output "website_url" {
  value       = "https://${var.domain_name}"
  description = "The URL of the website"
}

# ECRリポジトリのURL
# Dockerイメージのプッシュ先
output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}

# VPC ID
# 他のリソースの作成時に参照可能
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

# ECSクラスター名
# AWS CLIやコンソールでの操作時に使用
output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "The name of the ECS cluster"
}

# ECSサービス名
# サービスの更新や管理に使用
output "ecs_service_name" {
  value       = aws_ecs_service.main.name
  description = "The name of the ECS service"
}