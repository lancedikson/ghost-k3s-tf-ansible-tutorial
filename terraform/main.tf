variable "hcloud_token" {}

terraform {
  backend "http" {
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_location" "location" {
  name = "fsn1"
}

# TODO: provide your public key here
resource "hcloud_ssh_key" "user-ssh" {
  name       = "yourname"
  public_key = "ssh-ed25519 AAAAxxxxksdjfweiuwefiw username"
}

resource "hcloud_server" "server" {
  name        = "server-0"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  location    = data.hcloud_location.location.name
  ssh_keys    = [hcloud_ssh_key.user-ssh.id]
  labels = {
    "k8s/server" = "true",
    "k8s/agent"  = "true"
  }
  firewall_ids = [hcloud_firewall.base.id, hcloud_firewall.k3s-tf-tutorial-server.id]
}

resource "hcloud_network" "k3s-tf-tutorial" {
  name     = "k3s-tf-tutorial"
  ip_range = "10.29.0.0/16"
}

resource "hcloud_network_subnet" "k3s-tf-tutorial" {
  network_id   = hcloud_network.k3s-tf-tutorial.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.29.0.0/24"
}

resource "hcloud_server_network" "server" {
  server_id  = hcloud_server.server.id
  network_id = hcloud_network.k3s-tf-tutorial.id
}

resource "hcloud_firewall" "base" {
  name = "base"
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "k3s-tf-tutorial-server" {
  name = "k3s-tf-tutorial-server"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
