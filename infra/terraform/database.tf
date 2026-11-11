# 分析用RDS。inboundは許可IPのみ（盗んだ認証情報があれば、この経路で直接到達できる）
resource "aws_security_group" "rds" {
  name        = "dast-demo-rds-sg"
  description = "Analytics RDS. Inbound restricted to allowed IP only." # AWSのGroupDescriptionはASCIIのみ対応
  vpc_id      = aws_vpc.main.id

  # 意図的な穴（vulnerable時のみ）：許可IPから直接RDSへ到達できる経路。secure時は作らない。
  dynamic "ingress" {
    for_each = var.vulnerable ? [1] : []
    content {
      description = "PostgreSQL from allowed IP (vuln only)"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.allowed_ip]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dast-demo-rds-sg" }
}

resource "aws_db_instance" "analytics" {
  identifier             = "dast-demo-analytics-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # 意図的な穴（vulnerable時のみ）：本来は false にすべき公開設定。secure時は非公開。
  publicly_accessible = var.vulnerable

  skip_final_snapshot = true
  deletion_protection = false

  tags = { Name = "dast-demo-analytics-db" }
}
