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
  }

  backend "s3" {
    encrypt = true
  }
}

variable "domain" {
  description = "Domain (no www)"
}
