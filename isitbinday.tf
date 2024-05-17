variable "iibd_domain" {
  description = "Domain (no www)"
  default     = "isitbinday.com"
}

variable "iibd_zoneid" {
  description = "Cloudflare zone ID"
}

resource "aws_sesv2_email_identity" "iibd_email" {
  email_identity = var.iibd_domain
}

resource "aws_iam_user" "iibd_iam_user" {
  name = "${replace(var.iibd_domain, ".", "-")}-primary"
}

resource "aws_iam_access_key" "iibd_access_key" {
  user = aws_iam_user.iibd_iam_user.name
}

resource "aws_iam_policy" "iibd_ses_policy" {
  name   = "${replace(var.iibd_domain, ".", "-")}-SES"
  policy = data.aws_iam_policy_document.ses_policy_document.json
}

resource "aws_iam_user_policy_attachment" "iibd_user_policy" {
  user       = aws_iam_user.iibd_iam_user.name
  policy_arn = aws_iam_policy.iibd_ses_policy.arn
}

output "IIBD_EMAIL_HOST_PASSWORD" {
  value = nonsensitive(aws_iam_access_key.iibd_access_key.ses_smtp_password_v4)
}

output "IIBD_EMAIL_HOST_USER" {
  value = aws_iam_access_key.iibd_access_key.id
}

output "IIBD_EMAIL_HOST" {
  value = "email-smtp.${var.aws_region}.amazonaws.com"
}

resource "cloudflare_record" "iibd_cname_dkim" {
  count = 3

  zone_id         = var.iibd_zoneid
  name            = "${aws_sesv2_email_identity.iibd_email.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.iibd_domain}"
  value           = "${aws_sesv2_email_identity.iibd_email.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"
  type            = "CNAME"
  proxied         = false
  comment         = "DKIM ${count.index} - SES"
  depends_on      = [aws_sesv2_email_identity.iibd_email]
  allow_overwrite = true
}

resource "cloudflare_record" "iibd_api" {
  name            = "api"
  proxied         = true
  type            = "AAAA"
  value           = hcloud_server.web.ipv6_address
  zone_id         = var.iibd_zoneid
  allow_overwrite = true
}
