# ALB用のセキュリティグループ
# インターネットからのHTTPS(443)アクセスのみを許可
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from internet"
  }

  egress {
    protocol    = "-1"  # すべてのプロトコル
    from_port   = 0     # すべてのポート
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.app_name}-alb-sg"
  }
}

# ECSタスク用のセキュリティグループ
# ALBからのトラフィックのみを許可（最小権限の原則）
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.alb.id]  # ALBのセキュリティグループからのみ許可
    description     = "Allow traffic from ALB only"
  }

  egress {
    protocol    = "-1"  # すべてのプロトコル
    from_port   = 0     # すべてのポート
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.app_name}-ecs-tasks-sg"
  }
}