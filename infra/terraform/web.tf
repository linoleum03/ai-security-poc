data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Webサーバ用。inboundは許可IPのみ
resource "aws_security_group" "web" {
  name        = "dast-demo-web-sg"
  description = "Web server. Inbound restricted to allowed IP only." # AWSのGroupDescriptionはASCIIのみ対応
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from allowed IP only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    description = "SSH from allowed IP only (troubleshooting)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  # AWS Security AgentのPrivate VPC Penetration Testing用。インターネットには公開しない
  ingress {
    description = "HTTP from within VPC only (AWS Security Agent private pentest)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dast-demo-web-sg" }
}

# AWS Security AgentのPenetration Test実行リソース（VPC内ENI）にアタッチする想定のSG
resource "aws_security_group" "pentest_runner" {
  name        = "dast-demo-pentest-runner-sg"
  description = "Attached to AWS Security Agent private VPC pentest runner. Outbound to VPC only."
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Reach demo web app within VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "DNS resolution for private hosted zone"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = { Name = "dast-demo-pentest-runner-sg" }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # 意図的な穴（vulnerable時のみ）：IMDSv1を許可（トークン不要でメタデータに到達）。secure時は IMDSv2 必須。
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = var.vulnerable ? "optional" : "required" # vuln=IMDSv1許可 / secure=IMDSv2必須
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    export HOME=/root
    dnf install -y php8.3 php8.3-cli php8.3-pdo php8.3-mbstring php8.3-xml php8.3-zip git unzip

    # AL2023同梱のnodejsはv18でvite-plus等が要求するNode20+/22+を満たさないため公式リポジトリから導入
    curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
    dnf install -y nodejs

    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    cd /opt
    git clone --branch ai-security/security-fix-poc https://github.com/linoleum03/ai-security-poc.git app
    cd /opt/app
    cp .env.example .env
    sed -i 's#^APP_URL=.*#APP_URL=http://0.0.0.0#' .env
    composer install --optimize-autoloader --no-interaction
    npm install
    npm run build
    php artisan key:generate --force
    touch database/database.sqlite
    php artisan migrate --seed --force

    cat > /etc/systemd/system/dast-demo-app.service << 'UNIT'
    [Unit]
    Description=DAST demo vulnerable app
    After=network.target

    [Service]
    WorkingDirectory=/opt/app
    ExecStart=/usr/bin/php artisan serve --host=0.0.0.0 --port=80
    Restart=always
    User=root

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now dast-demo-app.service
  EOF

  tags = { Name = "dast-demo-web" }
}
