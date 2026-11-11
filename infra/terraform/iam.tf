resource "aws_iam_role" "ec2_role" {
  name = "dast-demo-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "dast-demo-ec2-role" }
}

# 意図的な穴（vulnerable時のみ）：Web機能には不要な、ワイルドカードのSecrets Manager読み取り権限。
# secure時は作成しない（＝最小権限で、分析Secretsを読めない）。
resource "aws_iam_role_policy" "ec2_secrets_overpermissive" {
  count = var.vulnerable ? 1 : 0

  name = "dast-demo-overpermissive-secrets-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "dast-demo-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
