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

resource "cloudflare_record" "hosting" {
  name            = "hosting"
  proxied         = true
  type            = "AAAA"
  value           = hcloud_server.web.ipv6_address
  zone_id         = var.zoneid
  allow_overwrite = true
}

resource "cloudflare_record" "root" {
  name            = var.domain
  proxied         = true
  type            = "CNAME"
  value           = "hosting.${var.domain}"
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
    organization = "www.${var.domain}"
  }
}

resource "cloudflare_origin_ca_certificate" "origin_cert" {
  csr                  = tls_cert_request.origin_cert.cert_request_pem
  hostnames            = ["*.${var.domain}", var.domain]
  request_type         = "origin-rsa"
  requested_validity   = 5475
  min_days_for_renewal = 365
}

resource "cloudflare_page_rule" "non-www-to-www" {
  priority = 1
  status   = "active"
  target   = "${var.domain}/*"
  zone_id  = var.zoneid
  actions {
    forwarding_url {
      status_code = 301
      url         = "https://www.${var.domain}/$1"
    }
  }
}
