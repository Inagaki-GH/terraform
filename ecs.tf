# ECSクラスターの作成
# Fargateタスクを実行するための論理的なグループ
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"  # コンテナの詳細なモニタリングを有効化
  }
}

# ECSタスク定義
# コンテナの実行方法を定義
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"                  # Fargateで必須のネットワークモード
  requires_compatibilities = ["FARGATE"]               # Fargateランタイムを使用
  cpu                      = var.fargate_cpu           # タスクに割り当てるCPUユニット
  memory                   = var.fargate_memory        # タスクに割り当てるメモリ
  
  # コンテナ定義（JSON形式）
  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.container_image                  # 初期デプロイ用のコンテナイメージ
      essential = true                                 # このコンテナが必須（停止するとタスク全体が停止）
      portMappings = [
        {
          containerPort = var.app_port                 # コンテナ内のポート
          hostPort      = var.app_port                 # ホスト側のポート（awsvpcモードでは同じ値）
        }
      ]
      # CloudWatchログの設定
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.app_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# CloudWatchロググループ
# コンテナのログを保存する場所
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 30                               # ログの保持期間（日数）
}

# ECSサービス
# タスク定義に基づいてコンテナを実行・管理
resource "aws_ecs_service" "main" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id            # 所属するECSクラスター
  task_definition = aws_ecs_task_definition.app.arn    # 使用するタスク定義
  desired_count   = var.app_count                      # 実行するタスク数
  launch_type     = "FARGATE"                          # Fargateで実行
  
  # ネットワーク設定
  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]  # セキュリティグループ
    subnets          = aws_subnet.private[*].id           # スプラット演算子(*)を使用してすべてのプライベートサブネットを参照
    assign_public_ip = true                               # パブリックIPを割り当て（インターネットアクセス用）
  }
  
  # ロードバランサーとの統合
  load_balancer {
    target_group_arn = aws_lb_target_group.app.id      # ALBのターゲットグループ
    container_name   = var.app_name                    # トラフィックを受け取るコンテナ名
    container_port   = var.app_port                    # トラフィックを受け取るコンテナポート
  }
  
  # 依存関係の設定
  depends_on = [
    aws_lb_listener.https,                             # HTTPSリスナーが作成された後に作成
    aws_route_table_association.private                # プライベートサブネットのルートテーブル関連付け後に作成
  ]
}

# ECSタスク実行ロール
# ECSがAWSリソースにアクセスするための権限
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-task-execution-role"
  
  # ECSサービスがこのロールを引き受けることを許可
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECSタスク実行ロールに基本的なECS権限をアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECRアクセス用のIAMポリシー
# ECSがECRからイメージをプルするための権限
resource "aws_iam_policy" "ecr_access" {
  name        = "${var.app_name}-ecr-access-policy"
  description = "Policy that allows ECS to pull images from ECR"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",  # レイヤーのダウンロードURL取得
          "ecr:BatchGetImage",           # イメージのバッチ取得
          "ecr:BatchCheckLayerAvailability"  # レイヤーの存在確認
        ]
        Resource = aws_ecr_repository.app.arn  # 特定のECRリポジトリのみにアクセス
      }
    ]
  })
}

# ECRアクセスポリシーをECSタスク実行ロールにアタッチ
resource "aws_iam_role_policy_attachment" "ecs_ecr_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecr_access.arn
}