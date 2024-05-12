variable "aws_region" {
  description = "AWS region"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_sesv2_email_identity" "email" {
  email_identity = var.domain
}

resource "aws_iam_user" "primary" {
  name = "${replace(var.domain, ".", "-")}-primary"
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.primary.name
}

data "aws_iam_policy_document" "ses_policy_document" {
  statement {
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_policy" {
  name   = "${replace(var.domain, ".", "-")}-SES"
  policy = data.aws_iam_policy_document.ses_policy_document.json
}

resource "aws_iam_user_policy_attachment" "user_policy" {
  user       = aws_iam_user.primary.name
  policy_arn = aws_iam_policy.ses_policy.arn
}

output "SMTP_PASS" {
  value = nonsensitive(aws_iam_access_key.access_key.ses_smtp_password_v4)
}

output "SMTP_USER" {
  value = aws_iam_access_key.access_key.id
}

output "SMTP_HOST" {
  value = "email-smtp.${var.aws_region}.amazonaws.com"
}
