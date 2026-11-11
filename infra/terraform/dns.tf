# AWS Security AgentのPenetration Testing機能はターゲットにドメイン名を要求する。
# Private VPC検証を使うことで、公開ドメイン購入やTLS証明書なしに、
# VPC内部でのみ解決されるプライベートホストゾーンでこの要件を満たす。
resource "aws_route53_zone" "private" {
  name = "dast-demo.internal"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = { Name = "dast-demo-private-zone" }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "app.dast-demo.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.web.private_ip]
}
