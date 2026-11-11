# =============================================================================
# Claude（MCP）用 読み取り専用ロール（CSPM 収集・観測用）
#
# 目的:
#   Claude が aws-mcp 経由で、この dast-demo 対象アカウント(415081251017)の
#   クラウド構成（VPC/SG/IAM/S3/RDS公開設定/メタデータ等）を「読み取り専用」で
#   収集し、CSPM 監査のスナップショットを作れるようにする。
#   別アカウント 910507540864 の readonly ユーザからクロスアカウントで Assume。
#
# 安全策:
#   - ReadOnlyAccess（広い Get/List/Describe）を付与しつつ、
#     secretsmanager:GetSecretValue / kms:Decrypt / kms:GenerateDataKey を
#     明示 Deny（＝秘密値は読ませない。demo の秘密はダミーだが方針を統一）。
#   - 書き込み系は一切付与しない（[[feedback_aws_read_only]] 準拠）。
# =============================================================================

variable "claude_ro_trusted_principal" {
  description = "このロールを AssumeRole できる外部プリンシパル（既存 readonly ユーザ）"
  type        = string
  default     = "arn:aws:iam::910507540864:user/ai-security-readonly"
}

data "aws_iam_policy_document" "claude_readonly_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.claude_ro_trusted_principal]
    }
  }
}

resource "aws_iam_role" "claude_readonly" {
  name                 = "dast-demo-claude-readonly"
  description          = "Read-only access for Claude (MCP) CSPM collection. Secret values denied."
  assume_role_policy   = data.aws_iam_policy_document.claude_readonly_trust.json
  max_session_duration = 3600

  tags = { Name = "dast-demo-claude-readonly" }
}

resource "aws_iam_role_policy_attachment" "claude_readonly_ro" {
  role       = aws_iam_role.claude_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "claude_readonly_deny" {
  statement {
    sid    = "DenySecretValues"
    effect = "Deny"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "claude_readonly_deny" {
  name   = "deny-secret-values"
  role   = aws_iam_role.claude_readonly.id
  policy = data.aws_iam_policy_document.claude_readonly_deny.json
}

output "claude_readonly_role_arn" {
  description = "Claude(MCP)用 ReadOnly ロールの ARN（~/.aws/config の role_arn に設定）"
  value       = aws_iam_role.claude_readonly.arn
}
