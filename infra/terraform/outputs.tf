output "web_public_ip" {
  description = "EC2のパブリックIP（ここに /webhooks/test でアクセス）"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "分析用RDSのエンドポイント"
  value       = aws_db_instance.analytics.address
}

output "secret_arn" {
  description = "分析用DB認証情報のSecrets Manager ARN"
  value       = aws_secretsmanager_secret.analytics_db.arn
}
