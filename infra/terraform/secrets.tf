resource "aws_secretsmanager_secret" "analytics_db" {
  name        = "dast-demo/analytics-db-credentials"
  description = "分析用DBの認証情報（デモ用ダミー値。本物の秘密は一切含まない）"
  tags        = { Name = "dast-demo-analytics-db-secret" }

  # apply/destroyを繰り返すデモ環境のため、削除時は30日の復旧猶予を待たず即時削除する
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "analytics_db" {
  secret_id = aws_secretsmanager_secret.analytics_db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.analytics.address
    port     = 5432
    dbname   = var.db_name
  })
}
