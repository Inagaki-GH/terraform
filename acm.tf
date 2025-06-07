# ACM証明書の作成
# HTTPS通信に使用するSSL/TLS証明書
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name        # 証明書のドメイン名
  validation_method = "DNS"                  # DNS検証方式を使用

  lifecycle {
    create_before_destroy = true             # 証明書の更新時に新しい証明書を先に作成
  }

  tags = {
    Name = "${var.app_name}-certificate"
  }
}

# Route53のホストゾーン情報を取得
data "aws_route53_zone" "main" {
  name         = var.domain_name             # ドメイン名に一致するホストゾーン
  private_zone = false                       # パブリックホストゾーン
}

# ACM証明書のDNS検証用レコードを作成
resource "aws_route53_record" "cert_validation" {
  # for_eachを使用して証明書の検証オプションごとにDNSレコードを作成
  # domain_nameをキーとして使用し、各検証オプションの詳細を値として保持
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true                     # 既存のレコードを上書き
  name            = each.value.name          # レコード名
  records         = [each.value.record]      # レコード値
  ttl             = 60                       # TTL（秒）
  type            = each.value.type          # レコードタイプ
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ACM証明書の検証完了を待機
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  # 動的リスト内包表記を使用して、すべての検証レコードのFQDNを配列として取得
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ALB用のRoute53 Aレコード
# ドメイン名でアプリケーションにアクセスできるようにする
resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name                  # ドメイン名
  type    = "A"                              # Aレコード（IPアドレスへのマッピング）

  alias {
    name                   = aws_lb.main.dns_name    # ALBのDNS名
    zone_id                = aws_lb.main.zone_id     # ALBのホストゾーンID
    evaluate_target_health = true                    # ターゲットのヘルスチェックを評価
  }
}