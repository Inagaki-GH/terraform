# ECRリポジトリの作成
# コンテナイメージを保存するプライベートリポジトリ
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name  # リポジトリ名
  image_tag_mutability = "MUTABLE"                # イメージタグの上書きを許可

  image_scanning_configuration {
    scan_on_push = true                           # イメージプッシュ時に脆弱性スキャンを実行
  }

  tags = {
    Name = "${var.app_name}-ecr"
  }
}

# ECRライフサイクルポリシー
# 古いイメージを自動的に削除してストレージコストを削減
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"                   # すべてのタグに適用
          countType     = "imageCountMoreThan"    # イメージ数が指定値を超えた場合
          countNumber   = 5                       # 保持するイメージ数
        }
        action = {
          type = "expire"                         # 期限切れとしてマーク（削除）
        }
      }
    ]
  })
}