# =============================================================================
# 顧客配布用テンプレート：AIセキュリティ監査エンジン用 読み取り専用ロール（CSPM）
#
# 監査エンジン(SaaS)が CSPM 監査のため、この顧客アカウントの構成を「読み取り専用」で
# 参照するためのロール。顧客は自アカウントでこれを作成する（IAM ユーザー/アクセスキーは不要）。
#   - 信頼: エンジンの broker ロールのみ ＋ 顧客ごとの ExternalId 条件（confused-deputy 対策）
#   - 権限: AWS 管理 ReadOnlyAccess ＋ 秘密値 Deny（secretsmanager:GetSecretValue / kms:Decrypt 等）
#   - ロール名は規約で固定（ai-security-audit-readonly）＝エンジン側は
#     arn:aws:iam::*:role/ai-security-audit-readonly 一本で全顧客に対応（顧客追加で engine 編集不要）
#
# PoC では dast-demo(415081251017) を「最初の顧客」として apply する。
# 本番では audit_engine_broker_principal と audit_external_id は運用側(エンジン)から受領する。
# =============================================================================

variable "audit_engine_broker_principal" {
  description = "監査エンジンの broker ロール ARN（このロールだけが Assume 可能）"
  type        = string
  default     = "arn:aws:iam::166952590531:role/ai-security-engine-broker-role"
}

variable "audit_external_id" {
  description = "エンジンが顧客ごとに発番する ExternalId（信頼条件）。本番は運用側から受領"
  type        = string
  default     = "aisec-31e64d7b-ef19-411a-8021-c386eb41ee88"
}

data "aws_iam_policy_document" "audit_readonly_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.audit_engine_broker_principal]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.audit_external_id]
    }
  }
}

resource "aws_iam_role" "audit_readonly" {
  name                 = "ai-security-audit-readonly"
  description          = "Read-only access for the AI security audit engine (CSPM). Secret values denied."
  assume_role_policy   = data.aws_iam_policy_document.audit_readonly_trust.json
  max_session_duration = 3600

  tags = { Name = "ai-security-audit-readonly" }
}

resource "aws_iam_role_policy_attachment" "audit_readonly_ro" {
  role       = aws_iam_role.audit_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "audit_readonly_deny" {
  statement {
    sid     = "DenySecretValues"
    effect  = "Deny"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "audit_readonly_deny" {
  name   = "deny-secret-values"
  role   = aws_iam_role.audit_readonly.id
  policy = data.aws_iam_policy_document.audit_readonly_deny.json
}

output "audit_readonly_role_arn" {
  description = "エンジンが Assume する顧客側 ReadOnly ロールの ARN"
  value       = aws_iam_role.audit_readonly.arn
}
