variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  sensitive   = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "zoneid" {
  description = "Cloudflare zone ID"
}

resource "cloudflare_record" "dokku-ipv6" {
  name            = "@"
  proxied         = true
  type            = "AAAA"
  value           = hcloud_server.web.ipv6_address
  zone_id         = var.zoneid
  allow_overwrite = true
}

resource "cloudflare_record" "dokku-ipv4" {
  name            = "@"
  proxied         = true
  type            = "A"
  value           = hcloud_server.web.ipv4_address
  zone_id         = var.zoneid
  allow_overwrite = true
}

resource "cloudflare_record" "ssh" {
  name            = "ssh"
  proxied         = false
  type            = "A"
  value           = hcloud_server.web.ipv4_address
  zone_id         = var.zoneid
  allow_overwrite = true
}

resource "cloudflare_record" "git" {
  name            = "git"
  proxied         = false
  type            = "A"
  value           = hcloud_server.web.ipv4_address
  zone_id         = var.zoneid
  allow_overwrite = true
}

resource "tls_private_key" "origin_cert" {
  algorithm = "RSA"
}

resource "tls_cert_request" "origin_cert" {
  private_key_pem = tls_private_key.origin_cert.private_key_pem

  subject {
    common_name  = ""
    organization = "hosting.${var.domain}"
  }
}

resource "cloudflare_origin_ca_certificate" "origin_cert" {
  csr                  = tls_cert_request.origin_cert.cert_request_pem
  hostnames            = ["*.${var.domain}", var.domain]
  request_type         = "origin-rsa"
  requested_validity   = 5475
  min_days_for_renewal = 365
}

resource "cloudflare_record" "cname_dkim" {
  count = 3

  zone_id         = var.zoneid
  name            = "${aws_sesv2_email_identity.email.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.domain}"
  value           = "${aws_sesv2_email_identity.email.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"
  type            = "CNAME"
  proxied         = false
  comment         = "DKIM ${count.index} - SES"
  depends_on      = [aws_sesv2_email_identity.email]
  allow_overwrite = true
}
