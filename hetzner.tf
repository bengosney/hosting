
variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_firewall" "webfirewall" {
  name = "web-firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "84.92.61.77/32",
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

data "template_file" "user_data" {
  template = file("./scripts/coolify.yaml")
}

resource "hcloud_server" "web" {
  name         = "web"
  image        = "ubuntu-24.04"
  server_type  = "cx11"
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.webfirewall.id]

  user_data = data.template_file.user_data.rendered


  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
}
