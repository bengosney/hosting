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

resource "aws_s3_bucket" "sql_backups" {
  bucket = "${replace(var.domain, ".", "-")}-sql-backups"
  force_destroy = true
}

resource "aws_iam_user" "sql_backup_user" {
  name = "${replace(var.domain, ".", "-")}-sql-backup"
}

resource "aws_iam_access_key" "sql_backup_key" {
  user = aws_iam_user.sql_backup_user.name
}

data "aws_iam_policy_document" "sql_backup_policy_doc" {
  statement {
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.sql_backups.arn,
      "${aws_s3_bucket.sql_backups.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "sql_backup_policy" {
  name   = "${replace(var.domain, ".", "-")}-sql-backup-policy"
  policy = data.aws_iam_policy_document.sql_backup_policy_doc.json
}

resource "aws_iam_user_policy_attachment" "sql_backup_user_policy" {
  user       = aws_iam_user.sql_backup_user.name
  policy_arn = aws_iam_policy.sql_backup_policy.arn
}

output "sql_backup_bucket_name" {
  value       = aws_s3_bucket.sql_backups.bucket
  description = "S3 bucket name for SQL backups"
}

output "sql_backup_access_key_id" {
  value       = aws_iam_access_key.sql_backup_key.id
  description = "Access key ID for SQL backup user"
  sensitive   = true
}

output "sql_backup_secret_access_key" {
  value       = aws_iam_access_key.sql_backup_key.secret
  description = "Secret access key for SQL backup user"
  sensitive   = true
}