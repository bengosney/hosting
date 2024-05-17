
variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "privNet" {
  name     = "privNet"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.privNet.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_firewall" "webfirewall" {
  name = "web-firewall"

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

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "84.92.61.77/32",
    ]
  }
}

variable "ssh_key" {
  description = "SSH public key"
}

data "template_file" "user_data" {
  template = file("./scripts/user-data.yaml")
  vars = {
    domain  = var.domain,
    ssh_key = var.ssh_key
  }
}

resource "hcloud_ssh_key" "default" {
  name       = "hetzner_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "hcloud_server" "web" {
  name         = "web"
  image        = "ubuntu-24.04"
  server_type  = "cpx11"
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.webfirewall.id]

  user_data = data.template_file.user_data.rendered
  ssh_keys  = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.privNet.id
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}
