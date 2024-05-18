terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.23.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    dokku = {
      source  = "aliksend/dokku"
      version = "~> 1.0.14"
    }
  }

  backend "s3" {
    encrypt = true
  }
}

variable "domain" {
  description = "Domain (no www)"
}

variable "email" {
  description = "Email address"
}
