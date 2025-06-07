# Application Load Balancer (ALB)の作成
# インターネット向け(external)のロードバランサー
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false                        # インターネット向け(external)
  load_balancer_type = "application"                # ALBタイプ
  security_groups    = [aws_security_group.alb.id]  # セキュリティグループの適用
  subnets            = aws_subnet.public[*].id      # スプラット演算子(*)を使用してすべてのパブリックサブネットを参照
  
  tags = {
    Name = "${var.app_name}-alb"
  }
}

# ALBのターゲットグループ
# ECSサービスのタスクがこのグループに登録される
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-target-group"
  port        = var.app_port                # アプリケーションポート
  protocol    = "HTTP"                      # ALBとターゲット間はHTTP通信
  vpc_id      = aws_vpc.main.id
  target_type = "ip"                        # Fargateの場合はIPアドレスでターゲット指定
  
  health_check {
    healthy_threshold   = 2                 # 正常判定するのに必要な連続成功回数
    unhealthy_threshold = 2                 # 異常判定するのに必要な連続失敗回数
    timeout             = 3                 # ヘルスチェックのタイムアウト秒数
    protocol            = "HTTP"
    path                = "/"               # ヘルスチェックパス
    interval            = 30                # ヘルスチェック間隔（秒）
  }
}

# HTTPSリスナーの設定
# ACM証明書を使用してHTTPS通信を有効化
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"  # セキュリティポリシー
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn  # 検証済みACM証明書
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id  # トラフィックの転送先
  }
}