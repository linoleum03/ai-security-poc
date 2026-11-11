variable "allowed_ip" {
  description = "接続を許可するIPアドレス（あなたのグローバルIP）。CIDR形式（例: 203.0.113.5/32）"
  type        = string
}

variable "vulnerable" {
  description = "意図的脆弱性のON/OFF。false=secure(対策後)、true=多段連鎖(対策前)。トポロジは同一で、この値だけが差分。"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "分析用データベースの名前"
  type        = string
  default     = "analytics"
}

variable "db_username" {
  description = "分析用DBのマスターユーザー名（ダミー）"
  type        = string
  default     = "analytics_admin"
}

variable "db_password" {
  description = "分析用DBのマスターパスワード（ダミー。本物の秘密は入れない）"
  type        = string
  sensitive   = true
  default     = "dummy-demo-password-2026"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDSインスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "budget_limit_usd" {
  description = "AWS Budgetsのアラート閾値（USD）"
  type        = number
  default     = 10
}

variable "budget_notification_email" {
  description = "予算超過時の通知先メールアドレス"
  type        = string
}
